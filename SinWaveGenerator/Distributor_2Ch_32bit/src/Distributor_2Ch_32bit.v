`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/18 11:31:51
// Design Name: 
// Module Name: Distributor_2Ch_32bit
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


module Distributor_2Ch_32bit(
    input [63:0] D,
    output wire [31:0] Q1,
    output wire [31:0] Q2
    );
    assign Q1 = D[63:32];
    assign Q2 = D[31:0];
endmodule
