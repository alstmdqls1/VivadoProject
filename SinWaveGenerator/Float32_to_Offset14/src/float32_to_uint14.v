`timescale 1ns/1ps

module float32_to_offset14 #(
    parameter integer PIPELINE_STAGES = 3
)(
    input  wire         aclk,
    input  wire         rst,

    // �Է� �� ��� ������
    input  wire [31:0]  float_in,
    output wire [13:0]  out_data
);

    //---------------------------------------------------------------
    // ���������� valid ��ȣ�� ������ ��������
    // (Stage1 ~ Stage3) �� PIPELINE_STAGES=3 �ܰ踦 ǥ��
    //---------------------------------------------------------------
    reg [PIPELINE_STAGES-1:0] valid_pipe;
    integer i;

    //---------------------------------------------------------------
    // Stage1 �������͵�
    //---------------------------------------------------------------
    reg [31:0] float_in_r1;
    reg        sign_r1;
    reg [7:0]  exponent_r1;
    reg [22:0] mantissa_r1;
    reg [23:0] frac24_r1;
    reg signed [9:0] exp_shift_r1;  // exponent-150

    //---------------------------------------------------------------
    // Stage2 �������͵�
    //---------------------------------------------------------------
    reg        sign_r2;
    reg [7:0]  exponent_r2;
    reg signed [9:0] exp_shift_r2;
    reg [23:0] frac24_r2;
    reg [38:0] abs_val_r2;  // ����Ʈ/�ݿø� ��� (�ִ� 39��Ʈ)

    //---------------------------------------------------------------
    // Stage3 �������͵� (���� ��� ��� �ܰ�)
    //---------------------------------------------------------------
    reg [7:0] exponent_r3;
    reg [38:0] abs_val_r3;
    reg signed [40:0] big_signed_val; // ���� ���� �� 39+1����
    reg signed [31:0] saturate_val;   // -8192~+8191
    integer offset_val;
    reg [13:0] next_out;
    reg [13:0] result_reg;    // ���� 14��Ʈ ����

    //---------------------------------------------------------------
    // (���������� ����) out_data ��������
    //---------------------------------------------------------------
    reg [13:0] out_data_r;

    //---------------------------------------------------------------
    // ���������� ���� always ���
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
            // valid ��ȣ ������ (Stage1 ~ StageN)
            //===================================================
            valid_pipe[0] <= 1'b1;  // �׻� ��ȿ�� �����Ͱ� ���´ٰ� ����
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
            end

            //---------------------------------------------------
            // Stage1: �ε��Ҽ��� �Ľ�
            //---------------------------------------------------
            float_in_r1 = float_in;

            sign_r1     <= float_in_r1[31];
            exponent_r1 <= float_in_r1[30:23];
            mantissa_r1 <= float_in_r1[22:0];

            // ����/�����Կ� ���� hidden bit ����
            if (exponent_r1 == 8'd0)
                frac24_r1 = {1'b0, mantissa_r1};
            else
                frac24_r1 = {1'b1, mantissa_r1};

            // exp_shift = exponent - 150
            exp_shift_r1 = $signed({1'b0, exponent_r1}) - 150;

            //---------------------------------------------------
            // Stage2: ����Ʈ(����ȭ) + �ݿø� => abs_val_r2
            //---------------------------------------------------
            sign_r2      <= sign_r1;
            exponent_r2  <= exponent_r1;
            exp_shift_r2 <= exp_shift_r1;
            frac24_r2    <= frac24_r1;

            begin : SHIFT_STAGE
                integer shift_amt;
                reg [63:0] big_frac;    // 64��Ʈ ���
                reg [63:0] round_add;   // 64��Ʈ �ݿø�

                if (exp_shift_r1 >= 0) begin
                    // ���� ����Ʈ
                    abs_val_r2 = frac24_r1 << exp_shift_r1;
                end else begin
                    shift_amt = -exp_shift_r1; // ���
                    if (shift_amt > 0) begin
                        // 64��Ʈ�� ����
                        big_frac = frac24_r1;
                        // round_add = 1 << (shift_amt-1) (64��Ʈ)
                        round_add = 64'd1 << (shift_amt - 1);

                        // �ݿø�
                        big_frac = big_frac + round_add;
                        // ����Ʈ �� 39��Ʈ��
                        abs_val_r2 = big_frac[38:0] >> shift_amt;
                    end else begin
                        abs_val_r2 = frac24_r1;
                    end
                end
            end

            //---------------------------------------------------
            // Stage3: ��ȣ ���� + Saturation + Offset
            //---------------------------------------------------
            begin : SAT_STAGE
            
                exponent_r3 <= exponent_r2;
                abs_val_r3 <= abs_val_r2;
                
                // Inf/NaN üũ
                if (exponent_r3 == 8'hFF) begin
                    big_signed_val = 8191; // +�� ���
                end
                else begin
                    // ��ȣ ����
                    if (sign_r2)
                        big_signed_val = -$signed(abs_val_r3);
                    else
                        big_signed_val = $signed(abs_val_r3);
                end

                // -8192 ~ +8191 ��ȭ
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

            // ���������� ���� ��� ��������
            out_data_r <= result_reg;
        end
    end // always

    //---------------------------------------------------------------
    // ���� ��� ������
    //---------------------------------------------------------------
    assign out_data = out_data_r;

endmodule