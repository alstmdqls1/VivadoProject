`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/19 19:27:59
// Design Name: 
// Module Name: FtoU14
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FtoU14(

    );
    reg clk = 0;
    reg [31:0] float_in;
    wire [13:0] out_data;
    reg[31:0] result;
    integer sum;
    float32_to_offset14 float32_to_offset14(
    .aclk(clk),
    .float_in(float_in),
    .out_data(out_data),
    .rst(0)
    );
    
    initial begin
        float_in = 32'b01000100110110010000101111011111;
        #10 float_in = 32'b01000101111000000000001111101111;
        #10 float_in = 32'b01000101111100001011111011100100;
        #10 float_in = 32'b01000101001110100001010011111001;
        #10 float_in = 32'b11000101011011000111010001100010;
        #10 float_in = 32'b11000101111110001011001101101011;
        #10 float_in = 32'b11000101110100010101001101110101;
        #10 float_in = 32'b11000100010110000001010100111100;
        #10 float_in = 32'b01000101101011011100110110011011;
        #10 float_in = 32'b01000101111111111101111011000100;
    end
    always @(posedge clk)begin
        result = out_data;
        sum = result - 8192;
    end
    always begin
        #5 clk =~ clk;
    end
    
endmodule
