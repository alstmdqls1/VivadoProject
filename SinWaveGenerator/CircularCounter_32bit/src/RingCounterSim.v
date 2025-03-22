`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/27 16:34:16
// Design Name: 
// Module Name: RingCounterSim
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


module CircularCounterSim(
        
    );
    
    reg clk = 1;
    reg sclr;
    reg [31:0]cnt;
    wire[31:0] count_out;
    
    CircularCounter32bit CircularCounter32bit_inst(
    .CLK(clk),
    .SCLR(sclr),
    .increment_value(cnt),
    .count_out(count_out)
    );
    
    initial begin
        sclr = 1;
        #10 sclr = 0;
        cnt = 4000;
     end
        
    always begin
        #5 clk = ~clk;
    end
    
endmodule
