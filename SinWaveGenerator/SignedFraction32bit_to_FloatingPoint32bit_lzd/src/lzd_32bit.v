`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 21:07:00
// Design Name: 
// Module Name: lzd_32bit
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


module lzd_32bit (
    input  [31:0] in,
    output [5:0] lzd,       // 0~32
    output       all_zero
);
    wire [15:0] hi = in[31:16];
    wire [15:0] lo = in[15:0];
    
    wire [4:0] lzd_hi, lzd_lo;
    wire       az_hi, az_lo;
    
    lzd_16bit LZD_16_Hi (.in(hi), .lzd(lzd_hi), .all_zero(az_hi));
    lzd_16bit LZD_16_Lo (.in(lo), .lzd(lzd_lo), .all_zero(az_lo));
    
    assign all_zero = az_hi & az_lo;

    // hi가 전부 0이면 => leading zero = 16 + lzd_lo
    // 아니면 => lzd_hi
    wire [5:0] lzd_if_hi_zero = 16 + lzd_lo;
    assign lzd = az_hi ? lzd_if_hi_zero : {1'b0, lzd_hi};
endmodule


