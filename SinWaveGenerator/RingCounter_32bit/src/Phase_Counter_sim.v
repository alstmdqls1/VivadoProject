`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/19 10:03:49
// Design Name: 
// Module Name: Phase_Counter_sim
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


module Phase_Counter_sim#(
    parameter integer WIDTH     = 16      // 카운터 비트 폭
    )();
    reg CLK = 1;
    reg [WIDTH-1:0] increment_value = 32;  // 증가(감소)량
    wire [WIDTH-1:0] count_out;
    
    ring_counter ring_counter(
    .increment_value(increment_value),
    .CLK(CLK),
    .count_out(count_out)
    );
   
   always begin
        #5 CLK =~ CLK;
   end
endmodule
    