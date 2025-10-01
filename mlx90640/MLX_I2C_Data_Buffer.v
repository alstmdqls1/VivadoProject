
`timescale 1ns/1ps

module MLX_I2C_Data_Buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  cmd,           // 0 = READ
    input  wire [7:0]  slaveAddr,     // 7-bit in [6:0]
    input  wire [15:0] regAddr,
    input  wire [31:0] length,
    input  wire        trig_in,
    input  wire        mlx_clk,       // observe-only (not used for timing)
    input  wire        debug_input,   // unused
    input  wire        mlx_sda,       // resolved SDA on bus

    output wire         clk_out,       // bus SCL
    output wire         m_data,        // master's SDA value when driving
    output wire        m_data_valid,  // 1 => master drives
    output wire        s_data_valid,  // 1 => slave should drive
    output wire  [2:0]  state,         // 0=IDLE,1=START,2=DATA,3=STOP
    output wire         data_window    // 1 => in 8-bit data window
);
    
    localparam SCL_LOW = 2'b000;
    localparam SCL_HIGH = 2'b001;
    localparam SCL_ACTIVE = 2'b11;
    
    localparam COMMAND_READ = 2'd0;
    localparam COMMAND_WRITE = 2'd1;
    
    localparam STATE_IDLE = 2'd0;
    localparam STATE_START = 2'd1;
    localparam STATE_DATA = 2'd2;
    localparam STATE_STOP = 2'd3;
    
    localparam START_INIT = 2'd0;
    localparam START_CHK_IDLE = 2'd1;
    localparam START_CHK_SDA = 2'd2;
    
    localparam DATA_ACCESS = 2'd0;
    localparam DATA_READ = 2'd1;
    localparam DATA_WRITE = 2'd2;
    
    localparam STOP_INIT = 2'd0;
    localparam STOP_CHK_IDLE = 2'd1;
    localparam STOP_CHK_SDA = 2'd2;
    
    localparam READ_SEQUENCE = 1'b0;
    localparam WRITE_SEQUENCE = 1'b1;
    
    localparam DATA_INIT = 2'd0;
    localparam DATA_SLOT = 2'd1;
    localparam ACK_SLOT = 2'd2;
    
    reg m_data_internal;
    reg clk_out_internal;
    reg trig_internal;
    reg s_data_valid_internal;
    reg m_data_valid_internal;
    reg data_window_internal;
    reg [31:0] length_internal;
    
    reg [2:0] next_state;
    reg [2:0] i2c_state;

    reg start_done;
    reg data_done;
    reg restart_req;
    reg stop_done;
    
    reg [1:0] start_state;
    reg [2:0] data_state;
    reg [1:0] stop_state;
    reg [1:0] scl_state;

    reg [3:0] access_byte_length;
    reg [31:0] read_byte_length;
    reg [3:0] write_byte_length;
    
    reg [7:0] bit_cnt;
    reg [7:0] tx_byte;
    reg [1:0] bit_seg;
    
    reg keep_read_sequence;
    reg master_nack_req;
    reg slave_ack_req;
    reg cmd_seq;    
    
    wire trig_rise = trig_in & ~trig_internal;
    
    always @(*) begin
        next_state = i2c_state;
        case (i2c_state)
            STATE_IDLE : begin
                if (trig_rise)
                    next_state = STATE_START;
            end
            STATE_START: begin 
                if (start_done) begin
                    next_state = STATE_DATA;
                end
            end
            STATE_DATA : begin
                if (data_done)
                    next_state = STATE_STOP;
                else if (restart_req) begin
                    next_state = STATE_START;
                end
            end
            STATE_STOP : begin
                if (stop_done)
                    next_state = STATE_IDLE;
            end
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_data_internal <= 1'b1;
            m_data_valid_internal <= 1'b1;
            s_data_valid_internal <= 1'b0;
            length_internal <= 32'b0;
            data_window_internal <= 1'b0;
            clk_out_internal <= 1'b1;
            scl_state <= SCL_HIGH;
            
            start_state <= START_INIT;
            data_state <= DATA_ACCESS;
            stop_state <= STOP_INIT;
            
            start_done  <= 1'b0;
            data_done <= 1'b0;
            stop_done <= 1'b0;
            
            bit_cnt <= 3'd7;
            tx_byte <= 1'b0;
            bit_seg <= DATA_INIT;
            cmd_seq <= 1'b0;
            
            access_byte_length <= 3'd2;
            read_byte_length <= 32'd2 + length_internal;
            write_byte_length <= 3'd0;
            
            master_nack_req <= 1'b0;
            slave_ack_req <= 1'b0;
            
            keep_read_sequence <= 1'b0;
        end else begin
            // STATE_IDLE
            length_internal <= length;
            if (i2c_state == STATE_IDLE) begin
                scl_state <= SCL_HIGH;
                m_data_internal <= 1'b1;
                m_data_valid_internal <= 1'b0;
                s_data_valid_internal <= 1'b0;
            end else begin
            
            end
            // === START 영역 (원본 조건/우선순위 보존) ===
            if (i2c_state != STATE_START) begin
                start_state <= START_INIT;
                start_done  <= 1'b0;
            end else begin
                m_data_valid_internal <= 1'b1;
                s_data_valid_internal <= 1'b0;
                case (start_state)
                    START_INIT : begin
                        m_data_internal <= 1'b1;
                        scl_state <= SCL_HIGH;
                        start_state <= START_CHK_IDLE;
                    end
                    START_CHK_IDLE : begin
                        if (mlx_sda == 1'b1 && mlx_clk == 1'b1) begin
                            m_data_internal <= 1'b0;
                            scl_state <= SCL_HIGH;
                            start_state             <= START_CHK_SDA;
                        end else begin
                            m_data_internal <= 1'b1;
                            scl_state <= SCL_HIGH;
                            start_state             <= START_CHK_IDLE;
                        end
                    end
                    START_CHK_SDA : begin
                        if (mlx_sda == 1'b0 && mlx_clk == 1'b1) begin
                            m_data_internal <= 1'b0;
                            scl_state <= SCL_LOW;
                            start_done <= 1'b1;
                        end else begin
                            m_data_internal <= 1'b0;
                            /*scl_state <= SCL_HIGH;*/
                            start_state             <= START_CHK_SDA;
                        end
                    end
                endcase
            end
    
            // === DATA 영역 (원본 조건/우선순위 보존) ===
            if (i2c_state == STATE_DATA) begin
                case (data_state)
                    DATA_ACCESS : begin
                        case (bit_seg)
                            DATA_INIT : begin
                                scl_state <= SCL_LOW;
                                tx_byte <= {slaveAddr[6:0], 1'b0};
                                bit_cnt <= 3'd7;
                                bit_seg <= DATA_SLOT;
                            end
                            DATA_SLOT : begin
                                scl_state <= SCL_ACTIVE;
                                
                                if(bit_cnt > 0) begin
                                    bit_cnt <= bit_cnt - 1;
                                end else begin
                                    bit_cnt <= 3'd7;
                                    bit_seg <= ACK_SLOT;
                                    if (access_byte_length > 0) begin
                                        access_byte_length <= access_byte_length - 1;
                                    end else begin
                                    case (cmd_seq)
                                        READ_SEQUENCE  : begin
                                            restart_req         <= 1'b1;
                                            keep_read_sequence  <= 1'b1;
                                        end
                                        WRITE_SEQUENCE : begin
                                            data_state          <= DATA_WRITE;
                                        end
                                    endcase
                                    end
                                end
    
                                m_data_internal <= tx_byte[bit_cnt];
                                m_data_valid_internal <= 1'b1;
                                s_data_valid_internal <= 1'b0;
                            end
                            ACK_SLOT : begin
                                m_data_internal <= 1'b1;
                                m_data_valid_internal <= 1'b0;
                                s_data_valid_internal <= 1'b1;
                                scl_state <= SCL_ACTIVE;                            
                                case(access_byte_length)
                                    4'd2 : tx_byte <= {slaveAddr[6:0], 1'b0};
                                    4'd1 : tx_byte <= regAddr[15:8];
                                    4'd0 : tx_byte <= regAddr[7:0];
                                endcase
                                bit_seg <= DATA_SLOT;
                            end
                        endcase
                    end 
    
                    DATA_READ : begin
                        case (bit_seg)
                            DATA_INIT : begin
                                scl_state <= SCL_LOW;
                                tx_byte <= {slaveAddr[6:0], 1'b1};
                                bit_cnt <= 3'd7;
                                bit_seg <= DATA_SLOT;
                            end
                            DATA_SLOT : begin
                                scl_state <= SCL_ACTIVE;
                                
                                if(bit_cnt > 0) begin
                                    bit_cnt <= bit_cnt - 1;
                                end else begin
                                    bit_cnt <= 3'd7;
                                    bit_seg <= ACK_SLOT;
                                    if (read_byte_length > 0) begin
                                        read_byte_length <= read_byte_length - 1;
                                    end else begin
                                        master_nack_req <= 1;
                                        data_done <= 1;
                                        keep_read_sequence <= 1'b0;
                                    end
                                end
                                if (read_byte_length < length + 32'd2) begin
                                    m_data_valid_internal <= 1'b0;
                                    s_data_valid_internal <= 1'b1;
                                    data_window_internal <= 1'b1;
                                end else begin
                                    slave_ack_req <= 1;
                                    m_data_valid_internal <= 1'b1;
                                    s_data_valid_internal <= 1'b0;
                                    data_window_internal <= 1'b0;
                                end
    
                                m_data_internal <= tx_byte[bit_cnt];
                            end
                            ACK_SLOT : begin
                                if(!slave_ack_req) begin
                                    if(!master_nack_req) begin
                                        m_data_internal <= 1'b0;
                                        master_nack_req <= 1'b0;
                                    end else begin
                                        m_data_internal <= 1'b1;
                                    end
                                    m_data_valid_internal <= 1'b1;
                                    s_data_valid_internal <= 1'b0;
                                end else begin
                                    m_data_internal <= 1'b1;
                                    m_data_valid_internal <= 1'b0;
                                    s_data_valid_internal <= 1'b1;
                                    slave_ack_req <= 1'b0;
                                end
                                tx_byte <= 8'b1111_1111;
                                scl_state <= SCL_ACTIVE;
                                bit_seg <= DATA_SLOT;
                                data_window_internal <= 1'b0;
                            end
                        endcase
                    end
    
                    DATA_WRITE : begin
                        case (bit_seg)
                            DATA_INIT : begin
                                
                            end
                            DATA_SLOT : begin
                                if (write_byte_length > 0) begin
                                    write_byte_length <= write_byte_length - 1;
                                end else begin
                                    // 원본: 비워둠
                                end
                            end
                            ACK_SLOT : begin
                                if (write_byte_length > 0) begin
                                    // Listen ACK (원본: 비워둠)
                                end else begin
                                    // Listen ACK
                                    data_done <= 1'b1; // 원본 유지
                                end
                            end
                        endcase
                    end
                endcase
            end else begin
                bit_cnt             <= 3'd7;
                bit_seg <= DATA_INIT;
                master_nack_req <= 1'b0;
                slave_ack_req <= 1'b0;
                restart_req            <= 1'b0;
                data_done              <= 1'b0;
                if (!keep_read_sequence) begin
                    data_state          <= DATA_ACCESS;
                    access_byte_length  <= 3'd2;
                    read_byte_length    <= 32'd2 + length_internal;
                    write_byte_length   <= 3'd1;
                end else begin
                    data_state          <= DATA_READ;
                end
            end
    
            // === STOP 영역 (원본 조건/우선순위 보존) ===
            if (i2c_state == STATE_STOP) begin
                case(stop_state) 
                    STOP_INIT : begin
                        m_data_internal <= 1'b0;
                        scl_state <= SCL_HIGH;
                        stop_state <= STOP_CHK_IDLE;
                    end
                    STOP_CHK_IDLE : begin
                        if(mlx_sda == 1'b0 && mlx_clk == 1'b1) begin
                            m_data_internal <= 1'b1;
                            scl_state <= SCL_HIGH;
                            stop_state <= STOP_CHK_SDA;
                        end
                    end
                    STOP_CHK_SDA : begin
                        if(mlx_sda == 1'b1 && mlx_clk == 1'b1) begin
                            m_data_internal <= 1'b1;
                            scl_state <= SCL_HIGH;
                            stop_done <= 1;
                        end
                    end
                endcase
                // 1. mlx_sda == low, mlx_clk == high
                // 2. mlx_sda == high, mlx_clk == high
                // 3. change state to STATE_IDLE
            end else begin
                stop_state <= STOP_INIT;
                stop_done <= 0;
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            i2c_state <= STATE_IDLE;
        end else begin
            i2c_state <= next_state;
            trig_internal <= trig_in;
            cmd_seq <= cmd[1:0]; 
        end
    end
    


    assign m_data = m_data_internal;
    assign clk_out = (scl_state == SCL_ACTIVE) ? clk :
                     (scl_state == SCL_LOW) ? 1'b0:
                     (scl_state == SCL_HIGH) ? 1'b1 : 1'b1;
    assign state = i2c_state;
    assign m_data_valid = m_data_valid_internal;
    assign s_data_valid = s_data_valid_internal;
    assign data_window = data_window_internal;
endmodule