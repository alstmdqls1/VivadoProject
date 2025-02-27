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
    output [2:0] lzd,      // leading zero ���� (0~4)
    output       all_zero
);
    // ���� 2��Ʈ, ���� 2��Ʈ�� ����
    wire [1:0] hi = in[3:2];
    wire [1:0] lo = in[1:0];
    
    // �� 2��Ʈ LZD ���
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
    
    // ���� 4��Ʈ LZD�� ����:
    // - ���� hi(���� 2��Ʈ)�� ���� 0�̸� => leading zero�� (2 + lo �κ��� lzd)
    // - �׷��� �ʴٸ� => hi �κ��� lzd
    // all_zero�� hi, lo ��� 0�� ���� 1
    assign all_zero = az_hi & az_lo;
    
    // hi�� ���� 0�̸� => leading zero = 2 + lzd_lo
    // hi�� 0�� �ƴϸ� => leading zero = lzd_hi
    // ��, 4��Ʈ ��ü���� �ִ� leading zero�� 4
    wire [2:0] lzd_if_hi_zero = 3'd2 + {1'b0, lzd_lo}; // (2 + lzd_lo)
    
    assign lzd = az_hi ? lzd_if_hi_zero
                       : {1'b0, lzd_hi};
endmodule

