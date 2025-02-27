`timescale 1ns / 1ps

module signedFraction32_to_floatingPoint32_lzd(
    input  wire        clk,
    input  wire [31:0] q_in,      // Q2.30 형식
    output reg  [31:0] float_out  // IEEE 754(단정도) 결과
);

    // Stage 1: 부호 & 절대값 변환
    reg        s1_sign;
    reg [30:0] s1_abs;

    always @(posedge clk) begin
        s1_sign <= q_in[31];
        s1_abs  <= q_in[31] ? (~q_in[30:0] + 1'b1) : q_in[30:0]; // 2의 보수 변환
    end

    // Stage 2: Leading Zero Detect (LZD)
    reg [4:0] s2_lzd_count;
    reg [30:0] s2_abs;

    wire [4:0] lzd_count;
    wire       all_zero;

    lzd_31bit U_lzd31(
        .in(s1_abs),
        .lzd(lzd_count),
        .all_zero(all_zero)
    );

    always @(posedge clk) begin
        s2_abs <= s1_abs;
        if (all_zero)
            s2_lzd_count <= 5'd31;
        else
            s2_lzd_count <= 31 - lzd_count;
    end

    // Stage 3: 정규화 (shift) + 지수 계산
    reg [7:0] s3_exp;
    reg [30:0] s3_shifted;

    always @(posedge clk) begin
        if (s2_lzd_count == 31) begin
            s3_exp  <= 8'd0;
            s3_shifted <= 56'd0;
        end else begin
            s3_shifted <= {s2_abs} << (30 - s2_lzd_count);
            s3_exp  <= (127 + (s2_lzd_count - 30)); // Bias 적용
        end
    end

    // Stage 4: Mantissa 추출 + Rounding + IEEE 754 변환
    reg [7:0]  final_exp;
    reg [22:0] final_mant;
    reg        final_sign;

    always @(posedge clk) begin
        final_sign <= s1_sign;

        if (s3_shifted == 56'd0) begin
            float_out = 32'd0; // Zero 처리
        end else begin
            if (s3_exp >= 255)
                final_exp = 8'd254;
            else
                final_exp = s3_exp;
        
            // Mantissa 추출 (Hidden bit 제외)
            final_mant = s3_shifted[29:7];

            // Infinity & NaN 처리
            if (final_exp == 8'd255) begin
                if (final_mant == 0)
                    float_out <= {final_sign, 8'd255, 23'd0}; // Infinity
                else
                    float_out <= {final_sign, 8'd255, 23'h400000}; // NaN
            end else begin
                float_out <= {final_sign, final_exp, final_mant};
            end
        end
    end

endmodule
