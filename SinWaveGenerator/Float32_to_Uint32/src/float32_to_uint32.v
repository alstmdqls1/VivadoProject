`timescale 1ns/1ps

module float32_to_uint32 #(
    parameter integer PIPELINE_STAGES = 3
)(
    input  wire         aclk,
    input  wire         rst,

    // 입력 및 출력 데이터
    input  wire [31:0]  float_in,
    output wire [31:0]  out_data
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
    // exponent - 150 ( = exponent - (127 + 23) )
    reg signed [9:0] exp_shift_r1;

    //---------------------------------------------------------------
    // Stage2 레지스터들
    //---------------------------------------------------------------
    reg        sign_r2;
    reg [7:0]  exponent_r2;
    reg signed [9:0] exp_shift_r2;
    reg [23:0] frac24_r2;
    // 쉬프트/반올림 결과 (최대 39비트 정도 여유)
    reg [38:0] abs_val_r2;

    //---------------------------------------------------------------
    // Stage3 레지스터들 (최종 결과 계산 단계)
    //---------------------------------------------------------------
    reg [7:0]   exponent_r3;
    reg [38:0]  abs_val_r3;
    // 부호/포화 처리를 위한 임시 변수
    reg signed [39:0] big_signed_val; 
    // 최종 32비트 범위로 포화하기 위한 레지스터
    reg [31:0] saturate_val;
    // 파이프라인 마지막 결과
    reg [31:0] result_reg;
    reg [31:0] out_data_r;

    //---------------------------------------------------------------
    // 파이프라인 메인 always 블록
    //---------------------------------------------------------------
    always @(posedge aclk or posedge rst) begin
        if (rst) begin
            //------------------------- Reset -------------------------
            valid_pipe      <= 0;

            // Stage1 init
            float_in_r1     <= 32'b0;
            sign_r1         <= 1'b0;
            exponent_r1     <= 8'd0;
            mantissa_r1     <= 23'b0;
            frac24_r1       <= 24'b0;
            exp_shift_r1    <= 10'sd0;

            // Stage2 init
            sign_r2         <= 1'b0;
            exponent_r2     <= 8'd0;
            exp_shift_r2    <= 10'sd0;
            frac24_r2       <= 24'b0;
            abs_val_r2      <= 39'b0;

            // Stage3 init
            exponent_r3     <= 8'd0;
            abs_val_r3      <= 39'b0;
            big_signed_val  <= 40'd0;
            saturate_val    <= 32'd0;
            result_reg      <= 32'd0;
            out_data_r      <= 32'd0;

        end else begin
            //-------------------------------------------------------
            // valid 신호 파이프 (Stage1 ~ StageN)
            //-------------------------------------------------------
            valid_pipe[0] <= 1'b1;  // 항상 유효한 데이터가 들어온다고 가정
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
            end

            //-------------------------------------------------------
            // Stage1: 부동소수점 파싱
            //-------------------------------------------------------
            float_in_r1  = float_in;
            sign_r1      <= float_in[31];
            exponent_r1  <= float_in[30:23];
            mantissa_r1  <= float_in[22:0];

            // 정규/비정규에 따라 hidden bit 설정
            if (exponent_r1 == 8'd0)
                frac24_r1 = {1'b0, mantissa_r1};
            else
                frac24_r1 = {1'b1, mantissa_r1};

            // exp_shift = exponent - 150
            // (단정도 float 지수 127 + 소수부 23 => 127+23=150)
            exp_shift_r1 = $signed({1'b0, exponent_r1}) - 150;

            //-------------------------------------------------------
            // Stage2: 쉬프트(정수화) + 반올림 => abs_val_r2
            //-------------------------------------------------------
            sign_r2         <= sign_r1;
            exponent_r2     <= exponent_r1;
            exp_shift_r2    <= exp_shift_r1;
            frac24_r2       <= frac24_r1;

            begin : SHIFT_STAGE
                integer shift_amt;
                reg [63:0] big_frac;    // 64비트 사용
                reg [63:0] round_add;   // 반올림용

                if (exp_shift_r1 >= 0) begin
                    // 왼쪽 시프트
                    abs_val_r2 = frac24_r1 << exp_shift_r1;
                end else begin
                    // exp_shift_r1이 음수면, 오른쪽 시프트
                    shift_amt = -exp_shift_r1;
                    if (shift_amt > 0) begin
                        // 64비트에 frac24_r1 복사
                        big_frac  = frac24_r1;
                        // round_add = 1 << (shift_amt-1)
                        round_add = 64'd1 << (shift_amt - 1);

                        // 반올림(최소 절반 이상이면 +1)
                        big_frac  = big_frac + round_add;
                        // 시프트 후 39비트 정도만 취함
                        abs_val_r2 = big_frac[38:0] >> shift_amt;
                    end else begin
                        abs_val_r2 = frac24_r1;
                    end
                end
            end

            //-------------------------------------------------------
            // Stage3: 부호 적용 + Saturation (0 ~ 2^32-1)
            //-------------------------------------------------------
            exponent_r3    <= exponent_r2;
            abs_val_r3     <= abs_val_r2;

            // 부호 포함 더 큰 범위 임시 변수
            if (exponent_r2 == 8'hFF) begin
                // Inf or NaN
                // 음수면 0으로, 양수면 최대값(0xFFFFFFFF)으로 포화
                big_signed_val = sign_r2 ? 40'd0 : 40'hFFFFFFFF;
            end
            else begin
                // 실제 abs 값 적용
                if (sign_r2) begin
                    // 음수이면 0으로 (unsigned 변환 시)
                    big_signed_val = 0;
                end else begin
                    // 양수이면 abs_val 그대로
                    big_signed_val = $signed(abs_val_r3);
                end
            end

            // 32비트 범위 포화
            // 0 <= saturate_val <= 0xFFFFFFFF
            if (big_signed_val < 0) begin
                saturate_val = 32'd0;
            end else if (big_signed_val > 32'hFFFFFFFF) begin
                saturate_val = 32'hFFFFFFFF;
            end else begin
                saturate_val = big_signed_val[31:0];
            end

            // 최종 파이프라인 결과
            result_reg = saturate_val;
            out_data_r <= result_reg;
        end
    end

    //---------------------------------------------------------------
    // 최종 출력
    //---------------------------------------------------------------
    assign out_data = out_data_r;

endmodule