`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 10:26:17
// Design Name: 
// Module Name: RingCounter_16bit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   Ring Counter for CODIC (6.0)용 CORDIC 입력값 생성.  
//   START와 END 값을 파라미터로 설정할 수 있으며, wrap-around 시 step 오프셋을 보정함.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - 수정: 65535~57344 구간에서 increment_value보다 1 더 크게 변하는 문제 보정
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RingCounter_16bit#(
    parameter integer WIDTH = 16,               // counter's data width
    parameter [WIDTH-1:0] START_VAL = 16'd8191,   // counter 시작점
    parameter [WIDTH-1:0] END_VAL   = 16'd57344,   // counter 종료점
    parameter DIRECTION = 0                     // 0 == down counter, 1 == up counter
)
(
    input  wire                  CLK,
    input  wire                  SCLR,
    // 매 클록마다 증가(감소)할 값을 동적으로 입력
    input  wire [WIDTH-1:0]      increment_value,
    output reg  [WIDTH-1:0]      count_out = START_VAL
);

    // START_VAL ~ END_VAL 범위의 길이
    // (참고: UP 카운터일 경우엔 END_VAL>=START_VAL 전제로 계산)
    localparam [WIDTH:0] RANGE_SIZE = END_VAL - START_VAL + 1;

    // 내부에서 leftover 계산 시 WIDTH+1 비트까지 사용(오버플로 대비)
    reg [WIDTH:0] boundary_dist; // 경계까지 남은 거리
    reg [WIDTH:0] leftover;      // 경계를 초과(또는 미달)한 분량
    reg [WIDTH-1:0] next_count;

    // 추가: 음수 판정 및 65535(0xFFFF) 스킵을 위한 임시 변수
    // signed로 선언하면 < 0 여부를 바로 확인할 수 있음
    reg signed [WIDTH:0] temp_signed;

    always @(posedge CLK or posedge SCLR) begin
        if (SCLR) begin
            count_out <= START_VAL;
        end
        else begin
            if (DIRECTION) begin
                //----------------------------------------------------------
                // Up 카운트
                //----------------------------------------------------------
                if (count_out <= END_VAL) begin
                    boundary_dist = END_VAL - count_out;
                end
                else begin
                    boundary_dist = (END_VAL + 1) + ((1 << WIDTH) - count_out);
                end

                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    next_count = START_VAL + leftover[WIDTH-1:0];
                end
                else begin
                    next_count = count_out + increment_value;
                end
            end
            else begin
                //----------------------------------------------------------
                // Down 카운트
                //----------------------------------------------------------
                if (count_out >= END_VAL) begin
                    boundary_dist = count_out - END_VAL;
                end
                else begin
                    // count_out가 낮은 영역(0~8191)인 경우, 
                    // 65535(0xFFFF)를 건너뛰기 위해 ((1 << WIDTH)-1) 대신 -1을 추가
                    boundary_dist = count_out + (((1 << WIDTH) - 1) - END_VAL) - 1;
                end

                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    next_count = START_VAL - leftover[WIDTH-1:0];
                end
                else begin
                    // 단순 감소: 음수 발생 시, wrap-around 보정 (16비트 전체 범위인 65536을 더함)
                    temp_signed = $signed(count_out) - $signed(increment_value);
                    if (temp_signed < 0) begin
                        temp_signed = temp_signed + (1 << WIDTH);
                    end
                    next_count = temp_signed[WIDTH-1:0];
                end
            end
            count_out <= next_count;
        end
    end
endmodule
