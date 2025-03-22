`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/27 17:55:19
// Design Name: 
// Module Name: sim
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


module sim(

    );
    reg clk = 1;
    reg SCLR;
    reg[15:0] increment_value;
    wire [15:0] phase_out;
    
    RingCounter_16bit ringcounter(
    .CLK(clk),
    .SCLR(SCLR),
    .increment_value(increment_value),
    .count_out(phase_out)
    );
    
    initial begin
        SCLR = 1;
        #20 SCLR = 0;
        
        increment_value = 400;
    end
    
    always begin
        #5 clk =~ clk;
    end
endmodule
