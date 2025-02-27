`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 21:07:16
// Design Name: 
// Module Name: lzd_8bit
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


module lzd_8bit (
    input  [7:0] in,
    output [3:0] lzd,      // 0~8
    output       all_zero
);
    // 상위 4비트, 하위 4비트
    wire [3:0] hi = in[7:4];
    wire [3:0] lo = in[3:0];

    wire [2:0] lzd_hi, lzd_lo;
    wire       az_hi, az_lo;
    
    lzd_4bit LZD_4_Hi (.in(hi), .lzd(lzd_hi), .all_zero(az_hi));
    lzd_4bit LZD_4_Lo (.in(lo), .lzd(lzd_lo), .all_zero(az_lo));
    
    assign all_zero = az_hi & az_lo;

    // hi가 전부 0이면 => leading zero = 4 + lzd_lo
    // 아니면 => lzd_hi
    wire [3:0] lzd_if_hi_zero = 4 + lzd_lo;
    assign lzd = az_hi ? lzd_if_hi_zero : {1'b0, lzd_hi};
endmodule
