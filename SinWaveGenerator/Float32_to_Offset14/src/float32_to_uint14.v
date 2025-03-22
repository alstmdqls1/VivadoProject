`timescale 1ns/1ps

module float32_to_offset14 #(
    parameter integer PIPELINE_STAGES = 3
)(
    input  wire         aclk,
    input  wire         rst,

    // 입력 및 출력 데이터
    input  wire [31:0]  float_in,
    output wire [13:0]  out_data
);

    //---------------------------------------------------------------
    // 파이프라인 valid 신호를 관리할 레지스터
    // (Stage1 ~ Stage3) 총 PIPELINE_STAGES=3 단계를 표현
    //---------------------------------------------------------------
    reg [PIPELINE_STAGES-1:0] valid_pipe;
    integer i;

    //---------------------------------------------------------------
    // Stage1 레지스터들
    //---------------------------------------------------------------
    reg [31:0] float_in_r1;
    reg        sign_r1;
    reg [7:0]  exponent_r1;
    reg [22:0] mantissa_r1;
    reg [23:0] frac24_r1;
    reg signed [9:0] exp_shift_r1;  // exponent-150

    //---------------------------------------------------------------
    // Stage2 레지스터들
    //---------------------------------------------------------------
    reg        sign_r2;
    reg [7:0]  exponent_r2;
    reg signed [9:0] exp_shift_r2;
    reg [23:0] frac24_r2;
    reg [38:0] abs_val_r2;  // 쉬프트/반올림 결과 (최대 39비트)

    //---------------------------------------------------------------
    // Stage3 레지스터들 (최종 결과 계산 단계)
    //---------------------------------------------------------------
    reg [7:0] exponent_r3;
    reg [38:0] abs_val_r3;
    reg signed [40:0] big_signed_val; // 음수 반전 시 39+1여유
    reg signed [31:0] saturate_val;   // -8192~+8191
    integer offset_val;
    reg [13:0] next_out;
    reg [13:0] result_reg;    // 최종 14비트 저장

    //---------------------------------------------------------------
    // (파이프라인 최종) out_data 레지스터
    //---------------------------------------------------------------
    reg [13:0] out_data_r;

    //---------------------------------------------------------------
    // 파이프라인 메인 always 블록
    //---------------------------------------------------------------
    always @(posedge aclk or posedge rst) begin
        if (rst) begin
            //------------------------- Reset -------------------------
            valid_pipe  <= 0;

            // Stage1 init
            float_in_r1 <= 32'b0;
            sign_r1     <= 1'b0;
            exponent_r1 <= 8'd0;
            mantissa_r1 <= 23'b0;
            frac24_r1   <= 24'b0;
            exp_shift_r1<= 10'sd0;

            // Stage2 init
            sign_r2      <= 1'b0;
            exponent_r2  <= 8'd0;
            exp_shift_r2 <= 10'sd0;
            frac24_r2    <= 24'b0;
            abs_val_r2   <= 39'b0;

            // Stage3 init
            exponent_r3    <= 8'd0;
            big_signed_val <= 0;
            saturate_val   <= 0;
            offset_val     <= 0;
            next_out       <= 14'd0;
            result_reg     <= 14'd0;
            out_data_r     <= 14'd0;

        end else begin
            //===================================================
            // valid 신호 파이프 (Stage1 ~ StageN)
            //===================================================
            valid_pipe[0] <= 1'b1;  // 항상 유효한 데이터가 들어온다고 가정
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
            end

            //---------------------------------------------------
            // Stage1: 부동소수점 파싱
            //---------------------------------------------------
            float_in_r1 = float_in;

            sign_r1     <= float_in_r1[31];
            exponent_r1 <= float_in_r1[30:23];
            mantissa_r1 <= float_in_r1[22:0];

            // 정규/비정규에 따라 hidden bit 설정
            if (exponent_r1 == 8'd0)
                frac24_r1 = {1'b0, mantissa_r1};
            else
                frac24_r1 = {1'b1, mantissa_r1};

            // exp_shift = exponent - 150
            exp_shift_r1 = $signed({1'b0, exponent_r1}) - 150;

            //---------------------------------------------------
            // Stage2: 쉬프트(정수화) + 반올림 => abs_val_r2
            //---------------------------------------------------
            sign_r2      <= sign_r1;
            exponent_r2  <= exponent_r1;
            exp_shift_r2 <= exp_shift_r1;
            frac24_r2    <= frac24_r1;

            begin : SHIFT_STAGE
                integer shift_amt;
                reg [63:0] big_frac;    // 64비트 사용
                reg [63:0] round_add;   // 64비트 반올림

                if (exp_shift_r1 >= 0) begin
                    // 왼쪽 시프트
                    abs_val_r2 = frac24_r1 << exp_shift_r1;
                end else begin
                    shift_amt = -exp_shift_r1; // 양수
                    if (shift_amt > 0) begin
                        // 64비트에 복사
                        big_frac = frac24_r1;
                        // round_add = 1 << (shift_amt-1) (64비트)
                        round_add = 64'd1 << (shift_amt - 1);

                        // 반올림
                        big_frac = big_frac + round_add;
                        // 시프트 후 39비트로
                        abs_val_r2 = big_frac[38:0] >> shift_amt;
                    end else begin
                        abs_val_r2 = frac24_r1;
                    end
                end
            end

            //---------------------------------------------------
            // Stage3: 부호 적용 + Saturation + Offset
            //---------------------------------------------------
            begin : SAT_STAGE
            
                exponent_r3 <= exponent_r2;
                abs_val_r3 <= abs_val_r2;
                
                // Inf/NaN 체크
                if (exponent_r3 == 8'hFF) begin
                    big_signed_val = 8191; // +∞ 취급
                end
                else begin
                    // 부호 적용
                    if (sign_r2)
                        big_signed_val = -$signed(abs_val_r3);
                    else
                        big_signed_val = $signed(abs_val_r3);
                end

                // -8192 ~ +8191 포화
                if (big_signed_val > 8191)
                    saturate_val = 8191;
                else if (big_signed_val < -8192)
                    saturate_val = -8192;
                else
                    saturate_val = big_signed_val[31:0];

                // +8192 => 0..16383
                offset_val = saturate_val + 8192;
                if (offset_val < 0)
                    offset_val = 0;
                else if (offset_val > 16383)
                    offset_val = 16383;

                next_out   = offset_val[13:0];
                result_reg = next_out;
            end

            // 파이프라인 최종 출력 레지스터
            out_data_r <= result_reg;
        end
    end // always

    //---------------------------------------------------------------
    // 최종 출력 데이터
    //---------------------------------------------------------------
    assign out_data = out_data_r;

endmodule