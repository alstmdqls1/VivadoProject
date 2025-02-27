`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 12:59:12
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
    reg [13:0] offset_in;
    wire [13:0] dac_out;
    
    offsetBinary_to_2sComplement offsetBinary_to_2sComplement(
    .clk(clk),
    .offset_in(offset_in),
    .dac_out(dac_out)
    );
    
    initial begin
        offset_in = 14'd1000;
    end
    
    always begin
        #5 clk = ~clk;
        
    end
    
    always begin
        #10 offset_in = offset_in + 1;
    end
endmodule
