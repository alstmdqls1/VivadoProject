`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 10:26:17
// Design Name: 
// Module Name: RingCounter_16bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   Ring Counter for CODIC (6.0)�� CORDIC �Է°� ����.  
//   START�� END ���� �Ķ���ͷ� ������ �� ������, wrap-around �� step �������� ������.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - ����: 65535~57344 �������� increment_value���� 1 �� ũ�� ���ϴ� ���� ����
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RingCounter_16bit#(
    parameter integer WIDTH = 16,               // counter's data width
    parameter [WIDTH-1:0] START_VAL = 16'd8191,   // counter ������
    parameter [WIDTH-1:0] END_VAL   = 16'd57344,   // counter ������
    parameter DIRECTION = 0                     // 0 == down counter, 1 == up counter
)
(
    input  wire                  CLK,
    input  wire                  SCLR,
    // �� Ŭ�ϸ��� ����(����)�� ���� �������� �Է�
    input  wire [WIDTH-1:0]      increment_value,
    output reg  [WIDTH-1:0]      count_out = START_VAL
);

    // START_VAL ~ END_VAL ������ ����
    // (����: UP ī������ ��쿣 END_VAL>=START_VAL ������ ���)
    localparam [WIDTH:0] RANGE_SIZE = END_VAL - START_VAL + 1;

    // ���ο��� leftover ��� �� WIDTH+1 ��Ʈ���� ���(�����÷� ���)
    reg [WIDTH:0] boundary_dist; // ������ ���� �Ÿ�
    reg [WIDTH:0] leftover;      // ��踦 �ʰ�(�Ǵ� �̴�)�� �з�
    reg [WIDTH-1:0] next_count;

    // �߰�: ���� ���� �� 65535(0xFFFF) ��ŵ�� ���� �ӽ� ����
    // signed�� �����ϸ� < 0 ���θ� �ٷ� Ȯ���� �� ����
    reg signed [WIDTH:0] temp_signed;

    always @(posedge CLK or posedge SCLR) begin
        if (SCLR) begin
            count_out <= START_VAL;
        end
        else begin
            if (DIRECTION) begin
                //----------------------------------------------------------
                // Up ī��Ʈ
                //----------------------------------------------------------
                if (count_out <= END_VAL) begin
                    boundary_dist = END_VAL - count_out;
                end
                else begin
                    boundary_dist = (END_VAL + 1) + ((1 << WIDTH) - count_out);
                end

                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    next_count = START_VAL + leftover[WIDTH-1:0];
                end
                else begin
                    next_count = count_out + increment_value;
                end
            end
            else begin
                //----------------------------------------------------------
                // Down ī��Ʈ
                //----------------------------------------------------------
                if (count_out >= END_VAL) begin
                    boundary_dist = count_out - END_VAL;
                end
                else begin
                    // count_out�� ���� ����(0~8191)�� ���, 
                    // 65535(0xFFFF)�� �ǳʶٱ� ���� ((1 << WIDTH)-1) ��� -1�� �߰�
                    boundary_dist = count_out + (((1 << WIDTH) - 1) - END_VAL) - 1;
                end

                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    next_count = START_VAL - leftover[WIDTH-1:0];
                end
                else begin
                    // �ܼ� ����: ���� �߻� ��, wrap-around ���� (16��Ʈ ��ü ������ 65536�� ����)
                    temp_signed = $signed(count_out) - $signed(increment_value);
                    if (temp_signed < 0) begin
                        temp_signed = temp_signed + (1 << WIDTH);
                    end
                    next_count = temp_signed[WIDTH-1:0];
                end
            end
            count_out <= next_count;
        end
    end
endmodule
