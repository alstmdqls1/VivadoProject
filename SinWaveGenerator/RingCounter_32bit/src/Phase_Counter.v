module ring_counter #(
    parameter integer WIDTH = 32,
    parameter [WIDTH-1:0] START_VAL = 32'h20000000,   // counter start value
    parameter [WIDTH-1:0] END_VAL   = 32'h60000000,     // counter end value
    parameter DIRECTION = 0                           // 0: down, 1: up
)
(
    input  wire                  CLK,
    input  wire                  SCLR,
    // �� Ŭ�ϸ��� ����(����)�� ���� �������� �Է�
    input  wire [WIDTH-1:0]      increment_value,
    output reg  [WIDTH-1:0]      count_out = START_VAL
);

    // START_VAL ~ END_VAL ������ ���� (WIDTH+1 ��Ʈ)
    localparam [WIDTH:0] RANGE_SIZE = END_VAL - START_VAL + 1;

    // ���� ��꿡 ����� WIDTH+1 ��Ʈ �������͵�
    reg [WIDTH:0] boundary_dist; // ������ ���� �Ÿ�
    reg [WIDTH:0] leftover;      // ��踦 �ʰ��� �з�
    reg [WIDTH-1:0] next_count;

    // Down ī��Ʈ �� ���� ���� �� �ִ밪(0xFFFFFFFF) ��ŵ�� ���� �ӽ� ����
    reg signed [WIDTH:0] temp_signed;

    always @(posedge CLK or posedge SCLR) begin
        if (SCLR) begin
            count_out <= START_VAL;
        end
        else begin
            if (DIRECTION) begin
                //----------------------------------------------------------
                // Up ī��Ʈ
                //----------------------------------------------------------
                // ���� count_out���� END_VAL���� ���� �Ÿ� ���
                if (count_out <= END_VAL) begin
                    boundary_dist = END_VAL - count_out;
                end
                else begin
                    // �̹� ������ ��� ���, �� ���� ���ƿ� ������ ����
                    boundary_dist = (END_VAL + 1) + ((1 << WIDTH) - count_out);
                end

                // ���� �������� ���(dist)�� �ʰ��ϸ� ��� �Ѿ
                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    next_count = START_VAL + leftover[WIDTH-1:0];
                end
                else begin
                    // ��踦 ���� ������ �ܼ� ����
                    next_count = count_out + increment_value;
                end
            end
            else begin
                //----------------------------------------------------------
                // Down ī��Ʈ
                //----------------------------------------------------------
                if (count_out >= END_VAL) begin
                    boundary_dist = count_out - END_VAL;
                end
                else begin
                    // �̹� ������ ��� ��� ����
                    boundary_dist = count_out + (((1 << WIDTH) - 1) - END_VAL);
                end

                if (increment_value > boundary_dist) begin
                    leftover = increment_value - (boundary_dist + 1);
                    leftover = leftover % RANGE_SIZE;
                    // ��踦 �Ѿ����Ƿ� START_VAL���� ���ش�.
                    next_count = START_VAL - leftover[WIDTH-1:0];
                end
                else begin
                    // �ܼ� ����: ���� ������ ���� signed�� ���
                    temp_signed = $signed(count_out) - $signed(increment_value);
                    if (temp_signed < 0) begin
                        temp_signed = temp_signed + ((1 << WIDTH) - 1);
                    end
                    next_count = temp_signed[WIDTH-1:0];
                end
            end

            // --------------------------------------------------------------
            // ���� ����: Down ī��Ʈ �� �ְ�(0xFFFFFFFF)�� �ǳʶٷ���,
            // next_count�� 0xFFFFFFFF�̸� 0xFFFFFFFE�� ����
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