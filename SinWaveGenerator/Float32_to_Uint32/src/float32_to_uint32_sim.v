`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/21 15:49:12
// Design Name: 
// Module Name: float32_to_uint32_sim
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


module float32_to_uint32_sim(

    );
    reg clk = 1;
    reg rst_n;
    reg in_valid;
    reg[31:0] float_in;
    wire[31:0] out_data;
    wire out_valid;
    
    float32_to_uint32 float32_to_uint32(
    .aclk(clk),
    .aresetn(rst_n),
    .float_in(float_in),
    .out_data(out_data)
    );
    
    initial begin
        rst_n = 0;
        #5 in_valid = 1;
        rst_n = 1;
        float_in = 32'b01000110001001111100010110101100;
    end
    
    always begin
        #5 clk =~ clk;
    end
endmodule
