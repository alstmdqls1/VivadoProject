`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 21:07:23
// Design Name: 
// Module Name: lzd_4bit
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


module lzd_4bit (
    input  [3:0] in,
    output [2:0] lzd,      // leading zero 개수 (0~4)
    output       all_zero
);
    // 상위 2비트, 하위 2비트로 분할
    wire [1:0] hi = in[3:2];
    wire [1:0] lo = in[1:0];
    
    // 각 2비트 LZD 결과
    wire [1:0] lzd_hi;
    wire       az_hi;
    lzd_2bit LZD_Hi (
        .in(hi),
        .lzd(lzd_hi),
        .all_zero(az_hi)
    );
    
    wire [1:0] lzd_lo;
    wire       az_lo;
    lzd_2bit LZD_Lo (
        .in(lo),
        .lzd(lzd_lo),
        .all_zero(az_lo)
    );
    
    // 이제 4비트 LZD를 결정:
    // - 만약 hi(상위 2비트)가 전부 0이면 => leading zero는 (2 + lo 부분의 lzd)
    // - 그렇지 않다면 => hi 부분의 lzd
    // all_zero는 hi, lo 모두 0일 때만 1
    assign all_zero = az_hi & az_lo;
    
    // hi가 전부 0이면 => leading zero = 2 + lzd_lo
    // hi가 0이 아니면 => leading zero = lzd_hi
    // 단, 4비트 전체에서 최대 leading zero는 4
    wire [2:0] lzd_if_hi_zero = 3'd2 + {1'b0, lzd_lo}; // (2 + lzd_lo)
    
    assign lzd = az_hi ? lzd_if_hi_zero
                       : {1'b0, lzd_hi};
endmodule

