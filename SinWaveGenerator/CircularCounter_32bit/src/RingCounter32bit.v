`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/26 18:27:16
// Design Name: 
// Module Name: RingCounter32bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   32��Ʈ Ring Counter (Down/Up ��� ����)  
//   START�� END ���� �Ķ���ͷ� ������ �� ������, wrap-around �� step �������� ������.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - ����: 0xFFFFFFFF~END �������� increment_value���� 1�� �� ũ�� ��ȭ�ϴ� ���� ����
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// This IP is a Ring Counter. It operates in a unique manner and serves as a counter for inputting phase values in the Scaled Radians environment of the CORDIC (6.0) IP.
// The counter starts from START_VAL, underflows past zero to END_VAL, and then loops back to START_VAL, forming a perfect ring structure as it continuously underflows between START_VAL and END_VAL.
// Example : If WIDTH = 16, START_VAL = 8191, END_VAL = 57344, and increment_value = 3, the counter starts at 8191. When it passes 1, instead of jumping to 65535, it moves to 65534. The same behavior occurs when transitioning from END_VAL back to START_VAL, ensuring a seamless ring structure.
// Note : Both Down Counter and Up Counter modes have been implemented. While the Down Counter has been verified to work correctly, the functionality of the Up Counter still needs to be confirmed.
module CircularCounter32bit#(
    parameter integer WIDTH = 32,
    parameter [WIDTH-1:0] START_VAL = 32'h1FFFFFFF,   // counter start value
    parameter [WIDTH-1:0] END_VAL   = 32'hE0000000,     // counter end value
    parameter DIRECTION = 0                           // 0: down, 1: up
)
(
    input  wire                  CLK,
    input  wire                  SCLR,
    // �� Ŭ�ϸ��� ����(����)�� ���� �������� �Է�
    input  wire [WIDTH-1:0]      increment_value,
    output reg  [WIDTH-1:0]      count_out = START_VAL
);

    // START_VAL ~ END_VAL ������ ���� (WIDTH+1 ��Ʈ)
    localparam [WIDTH:0] RANGE_SIZE_UP = END_VAL - START_VAL + 1;
    localparam [WIDTH:0] RANGE_SIZE_DOWN = START_VAL + 1 + (1 << WIDTH) - END_VAL;    

    // ���� ��꿡 ����� WIDTH+1 ��Ʈ �������͵�
    reg [WIDTH:0] boundary_dist; // ������ ���� �Ÿ�
    reg [WIDTH:0] leftover;      // ��踦 �ʰ��� �з�
    reg [WIDTH-1:0] next_count;

    // Down ī��Ʈ �� ���� ���� �� �ִ밪(0xFFFFFFFF) ��ŵ�� ���� �ӽ� ����
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
                    leftover = leftover % RANGE_SIZE_UP;
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
                // After Underflow ~ END_VAL
                if (count_out >= END_VAL) begin
                    boundary_dist = count_out - END_VAL;
                end
                else begin
                    // �̹� ������ ��� ���, ������ ���� �Ÿ��� 1�� ����
                    // This is the boundary_dist when operating from START_VAL to 0.
                    boundary_dist = count_out + ((1 << WIDTH) - END_VAL);
                end
                // This describes the operation when increment_value is greater than boundary_dist.
                // It calculates the leftover to determine how much further the counter needs to move at the next jump point (START_VAL or END_VAL).
                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE_DOWN;
                    next_count = START_VAL - leftover[WIDTH-1:0];
                end
                
                else begin
                    // This describes the operation during simple decrement, where an underflow occurs if a negative value is generated.
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
