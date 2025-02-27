`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 12:57:50
// Design Name: 
// Module Name: offsetBinary_to_2sComplement
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


module offsetBinary_to_2sComplement(
    input  wire        clk,
    input  wire [13:0] offset_in,    // 14��Ʈ Offset Binary �Է�
    output reg  [13:0] dac_out       // Zmod DAC 1411���� ���� ��ȯ�� ���
    );
    
always @(posedge clk) begin
    if (offset_in[13] == 1'b1) begin
        // ���� ��: 8191 - (offset_in - 8192)
        dac_out = offset_in - 14'd8192;
    end else begin
        // ��� ��: 8191 - offset_in
        dac_out = 8191 + offset_in;
    end
end

endmodule
