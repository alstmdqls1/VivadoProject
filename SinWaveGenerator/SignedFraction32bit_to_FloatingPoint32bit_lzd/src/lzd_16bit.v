`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 21:07:09
// Design Name: 
// Module Name: lzd_16bit
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


module lzd_16bit (
    input  [15:0] in,
    output [4:0] lzd,      // 0~16
    output       all_zero
);
    wire [7:0] hi = in[15:8];
    wire [7:0] lo = in[7:0];
    
    wire [3:0] lzd_hi, lzd_lo;
    wire       az_hi, az_lo;
    
    lzd_8bit LZD_8_Hi (.in(hi), .lzd(lzd_hi), .all_zero(az_hi));
    lzd_8bit LZD_8_Lo (.in(lo), .lzd(lzd_lo), .all_zero(az_lo));
    
    assign all_zero = az_hi & az_lo;
    
    wire [4:0] lzd_if_hi_zero = 8 + lzd_lo;
    assign lzd = az_hi ? lzd_if_hi_zero : {1'b0, lzd_hi};
endmodule

