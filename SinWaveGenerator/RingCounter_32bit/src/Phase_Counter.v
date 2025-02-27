module ring_counter #(
    parameter integer WIDTH = 32,
    parameter [WIDTH-1:0] START_VAL = 32'h20000000,   // counter start value
    parameter [WIDTH-1:0] END_VAL   = 32'h60000000,     // counter end value
    parameter DIRECTION = 0                           // 0: down, 1: up
)
(
    input  wire                  CLK,
    input  wire                  SCLR,
    // 매 클록마다 증가(감소)할 값을 동적으로 입력
    input  wire [WIDTH-1:0]      increment_value,
    output reg  [WIDTH-1:0]      count_out = START_VAL
);

    // START_VAL ~ END_VAL 범위의 길이 (WIDTH+1 비트)
    localparam [WIDTH:0] RANGE_SIZE = END_VAL - START_VAL + 1;

    // 내부 계산에 사용할 WIDTH+1 비트 레지스터들
    reg [WIDTH:0] boundary_dist; // 경계까지 남은 거리
    reg [WIDTH:0] leftover;      // 경계를 초과한 분량
    reg [WIDTH-1:0] next_count;

    // Down 카운트 시 음수 판정 및 최대값(0xFFFFFFFF) 스킵을 위한 임시 변수
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
                // 현재 count_out에서 END_VAL까지 남은 거리 계산
                if (count_out <= END_VAL) begin
                    boundary_dist = END_VAL - count_out;
                end
                else begin
                    // 이미 범위를 벗어난 경우, 한 바퀴 돌아온 것으로 보정
                    boundary_dist = (END_VAL + 1) + ((1 << WIDTH) - count_out);
                end

                // 다음 증가량이 경계(dist)를 초과하면 경계 넘어섬
                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    next_count = START_VAL + leftover[WIDTH-1:0];
                end
                else begin
                    // 경계를 넘지 않으면 단순 증가
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
                    // 이미 범위를 벗어난 경우 보정
                    boundary_dist = count_out + (((1 << WIDTH) - 1) - END_VAL);
                end

                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    // 경계를 넘었으므로 START_VAL에서 빼준다.
                    next_count = START_VAL - leftover[WIDTH-1:0];
                end
                else begin
                    // 단순 감소: 음수 판정을 위해 signed로 계산
                    temp_signed = $signed(count_out) - $signed(increment_value);
                    if (temp_signed < 0) begin
                        temp_signed = temp_signed + ((1 << WIDTH) - 1);
                    end
                    next_count = temp_signed[WIDTH-1:0];
                end
            end

            // --------------------------------------------------------------
            // 최종 보정: Down 카운트 시 최고값(0xFFFFFFFF)을 건너뛰려면,
            // next_count가 0xFFFFFFFF이면 0xFFFFFFFE로 조정
            // --------------------------------------------------------------
            if (!DIRECTION) begin
                if (next_count == 32'hFFFFFFFF) begin
                    next_count = 32'hFFFFFFFE;
                end
            end

            count_out <= next_count;
        end
    end
endmodule