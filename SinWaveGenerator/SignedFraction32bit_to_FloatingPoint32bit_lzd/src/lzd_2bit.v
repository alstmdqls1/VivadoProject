`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 21:07:32
// Design Name: 
// Module Name: lzd_2bit
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


module lzd_2bit (
    input  [1:0] in,
    output [1:0] lzd,      // leading zero ���� (0~2)
    output       all_zero  // ��ü�� 0����
);
    wire b1 = in[1];
    wire b0 = in[0];
    
    // all_zero �Ǵ�
    assign all_zero = (in == 2'b00);

    // leading zero ����
    // 00 -> 2
    // 01 -> 1
    // 10 -> 0
    // 11 -> 0 (MSB�� �̹� 1�̹Ƿ� leading zero�� 0)
    assign lzd = (!b1 && !b0) ? 2'd2 :   // in=00
                 (!b1 &&  b0) ? 2'd1 :   // in=01
                 2'd0;                  // in=10 or 11
endmodule
