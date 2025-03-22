`timescale 1ns/1ps

module float32_to_uint32 #(
    parameter integer PIPELINE_STAGES = 3
)(
    input  wire         aclk,
    input  wire         rst,

    // �Է� �� ��� ������
    input  wire [31:0]  float_in,
    output wire [31:0]  out_data
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
    // exponent - 150 ( = exponent - (127 + 23) )
    reg signed [9:0] exp_shift_r1;

    //---------------------------------------------------------------
    // Stage2 �������͵�
    //---------------------------------------------------------------
    reg        sign_r2;
    reg [7:0]  exponent_r2;
    reg signed [9:0] exp_shift_r2;
    reg [23:0] frac24_r2;
    // ����Ʈ/�ݿø� ��� (�ִ� 39��Ʈ ���� ����)
    reg [38:0] abs_val_r2;

    //---------------------------------------------------------------
    // Stage3 �������͵� (���� ��� ��� �ܰ�)
    //---------------------------------------------------------------
    reg [7:0]   exponent_r3;
    reg [38:0]  abs_val_r3;
    // ��ȣ/��ȭ ó���� ���� �ӽ� ����
    reg signed [39:0] big_signed_val; 
    // ���� 32��Ʈ ������ ��ȭ�ϱ� ���� ��������
    reg [31:0] saturate_val;
    // ���������� ������ ���
    reg [31:0] result_reg;
    reg [31:0] out_data_r;

    //---------------------------------------------------------------
    // ���������� ���� always ���
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
            // valid ��ȣ ������ (Stage1 ~ StageN)
            //-------------------------------------------------------
            valid_pipe[0] <= 1'b1;  // �׻� ��ȿ�� �����Ͱ� ���´ٰ� ����
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                valid_pipe[i] <= valid_pipe[i-1];
            end

            //-------------------------------------------------------
            // Stage1: �ε��Ҽ��� �Ľ�
            //-------------------------------------------------------
            float_in_r1  = float_in;
            sign_r1      <= float_in[31];
            exponent_r1  <= float_in[30:23];
            mantissa_r1  <= float_in[22:0];

            // ����/�����Կ� ���� hidden bit ����
            if (exponent_r1 == 8'd0)
                frac24_r1 = {1'b0, mantissa_r1};
            else
                frac24_r1 = {1'b1, mantissa_r1};

            // exp_shift = exponent - 150
            // (������ float ���� 127 + �Ҽ��� 23 => 127+23=150)
            exp_shift_r1 = $signed({1'b0, exponent_r1}) - 150;

            //-------------------------------------------------------
            // Stage2: ����Ʈ(����ȭ) + �ݿø� => abs_val_r2
            //-------------------------------------------------------
            sign_r2         <= sign_r1;
            exponent_r2     <= exponent_r1;
            exp_shift_r2    <= exp_shift_r1;
            frac24_r2       <= frac24_r1;

            begin : SHIFT_STAGE
                integer shift_amt;
                reg [63:0] big_frac;    // 64��Ʈ ���
                reg [63:0] round_add;   // �ݿø���

                if (exp_shift_r1 >= 0) begin
                    // ���� ����Ʈ
                    abs_val_r2 = frac24_r1 << exp_shift_r1;
                end else begin
                    // exp_shift_r1�� ������, ������ ����Ʈ
                    shift_amt = -exp_shift_r1;
                    if (shift_amt > 0) begin
                        // 64��Ʈ�� frac24_r1 ����
                        big_frac  = frac24_r1;
                        // round_add = 1 << (shift_amt-1)
                        round_add = 64'd1 << (shift_amt - 1);

                        // �ݿø�(�ּ� ���� �̻��̸� +1)
                        big_frac  = big_frac + round_add;
                        // ����Ʈ �� 39��Ʈ ������ ����
                        abs_val_r2 = big_frac[38:0] >> shift_amt;
                    end else begin
                        abs_val_r2 = frac24_r1;
                    end
                end
            end

            //-------------------------------------------------------
            // Stage3: ��ȣ ���� + Saturation (0 ~ 2^32-1)
            //-------------------------------------------------------
            exponent_r3    <= exponent_r2;
            abs_val_r3     <= abs_val_r2;

            // ��ȣ ���� �� ū ���� �ӽ� ����
            if (exponent_r2 == 8'hFF) begin
                // Inf or NaN
                // ������ 0����, ����� �ִ밪(0xFFFFFFFF)���� ��ȭ
                big_signed_val = sign_r2 ? 40'd0 : 40'hFFFFFFFF;
            end
            else begin
                // ���� abs �� ����
                if (sign_r2) begin
                    // �����̸� 0���� (unsigned ��ȯ ��)
                    big_signed_val = 0;
                end else begin
                    // ����̸� abs_val �״��
                    big_signed_val = $signed(abs_val_r3);
                end
            end

            // 32��Ʈ ���� ��ȭ
            // 0 <= saturate_val <= 0xFFFFFFFF
            if (big_signed_val < 0) begin
                saturate_val = 32'd0;
            end else if (big_signed_val > 32'hFFFFFFFF) begin
                saturate_val = 32'hFFFFFFFF;
            end else begin
                saturate_val = big_signed_val[31:0];
            end

            // ���� ���������� ���
            result_reg = saturate_val;
            out_data_r <= result_reg;
        end
    end

    //---------------------------------------------------------------
    // ���� ���
    //---------------------------------------------------------------
    assign out_data = out_data_r;

endmodule