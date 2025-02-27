`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 21:06:49
// Design Name: 
// Module Name: lzd_31bit
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

module lzd_31bit (
    input  [30:0] in,
    output [4:0]  lzd,      // 0..31
    output        all_zero
);
    wire [31:0] extended = {1'b0, in}; // 상위 1비트=0
    wire [5:0]  lzd_32;
    wire        az_32;

    lzd_32bit U_lzd32(
        .in(extended),
        .lzd(lzd_32),
        .all_zero(az_32)
    );
    
    assign all_zero = az_32;
    // lzd_32=0..32 => 32면 전부0
    // 실제 31bit에 대해 0..31이므로 하위 5비트 사용
    assign lzd = (lzd_32 > 5'd31) ? 5'd31 : lzd_32[4:0];
endmodule
