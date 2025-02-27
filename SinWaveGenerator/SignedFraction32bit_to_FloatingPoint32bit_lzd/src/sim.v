`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/17 22:08:24
// Design Name: 
// Module Name: sFtofP
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
    reg aresetn = 0;
    wire [31:0] float_out;
    integer i;
    reg signed [31:0] q_in;
    
    wire [31:0] cp_float_out;
    signedFraction32_to_floatingPoint32_lzd SignedFraction32_to_Float32UUT(
     .clk(clk),
     .q_in(q_in),
     .float_out(float_out)
    );
    
    initial begin
        aresetn = 0;
        #30 aresetn = 1;
        // 예시 입력 1

    
    // -1.0 (Q2.30)
        /*q_in = 32'h40000000;  // -1.0 in Q2.30*/
        q_in = 32'b11000000000000000000000000000100;
        //00111111111111111111111111111100
    
        /*q_in = 32'hC0CCCCC;  // -1.1 in Q2.30 (정수부 [31:30] = 11, 소수부 변환 완료)*/
        
        /*for (i = 0; i <= 200000; i = i + 1) begin
            #10;  // 10ns마다 업데이트 (클럭 사이클에 맞춰 변경)
            q_in = q_in + 32'hA3D70A;  // +0.01 in Q2.30 (소수부 변환 완료)
            
            // Q2.30 범위 초과 방지
            if (q_in[31:30] == 2'b01 && q_in[29:0] > 30'h33333333) begin
                q_in = 32'hC0CCCCC;  // 다시 -1.1로 초기화
            end
        end*/
        end
    always begin
        #5 clk <= ~clk;
    end    
    
endmodule