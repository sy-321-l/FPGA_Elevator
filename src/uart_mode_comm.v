module uart_mode_comm
(
    input               clk,
    input               rst_n,
    input               uart_rx,     // 串口接收引脚，来自外部上位机
    output reg          uart_tx,     // 串口发送引脚，发给上位机
    input       [2:0]   curr_floor,
    input               dir_up,
    input               dir_down,
    input               door_open,
    output reg  [3:0]   mode
);

parameter BAUD_CNT_MAX = 16'd434;  // 50MHz 下 115200 波特分频
parameter CHAR_WID     = 4'd8;     // 数据位宽度，8位
localparam IDLE  = 2'b00;          // 空闲状态
localparam RX    = 2'b01;          // 接收状态
localparam TX    = 2'b10;          // 发送状态

reg [1:0] comm_state;     // 当前状态
reg [7:0] rx_buf [7:0];   // 接收缓存数组，最多存8个字节（一帧指令）
reg [2:0] rx_len;         // 当前已经接收了多少字节
reg [15:0] baud_cnt;      // 波特率计数器：数到434代表一位传完
reg [3:0]  bit_cnt;       // 位计数器：0=起始位, 1~8=数据位0~7, 9=停止位
reg [7:0]  rx_data;       // 单个字节的接收寄存器

reg        tx_req;        // 发送请求标志，有数据要发时拉高
reg [4:0]  tx_byte_cnt;   // 当前发送到第几个字节
reg [7:0]  tx_buf [31:0]; // 发送缓存数组，最多存32个字节的回显字符串
reg [4:0]  tx_total_len;  // 本次要发送的总字节数
reg frame_done;           // 一帧指令接收完成标志

// RX两级同步防亚稳态
reg uart_rx_sync1, uart_rx_sync2;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		  uart_rx_sync1 <= 1'b1;  // 复位默认拉高，串口空闲状态为高电平
        uart_rx_sync2 <= 1'b1;
    end else begin
        uart_rx_sync1 <= uart_rx;
        uart_rx_sync2 <= uart_rx_sync1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin  // 复位初始化，全部回到空闲、清零
        comm_state    <= IDLE;
        baud_cnt      <= 16'd0;
        bit_cnt       <= 4'd0;
        rx_len        <= 3'd0;
        mode          <= 4'b0001;  // 默认自动模式
        uart_tx       <= 1'b1;
        tx_req        <= 1'b0;
        tx_byte_cnt   <= 5'd0;
        tx_total_len  <= 5'd0;
        frame_done    <= 1'b0;
    end
    else begin
        frame_done <= 1'b0;  // 默认拉低，只有接收完成那一拍拉高

        case(comm_state)
        IDLE: begin
            baud_cnt <= 16'd0;
            bit_cnt  <= 4'd0;
            uart_tx  <= 1'b1;
            
            // 帧解析：延迟一拍，确保rx_buf数据稳定
            if(frame_done) begin
                tx_req <= 1'b0;
                // AUTO 指令匹配
                if(rx_buf[0]=="A" && rx_buf[1]=="U" && rx_buf[2]=="T" && rx_buf[3]=="O") begin
                    mode <= 4'b0001;
						  // 拼装回显字符串，写入tx_buf
                    tx_buf[0]  <= "F"; tx_buf[1]  <= ":"; tx_buf[2]  <= 8'h30 + curr_floor; tx_buf[3]  <= " ";
                    tx_buf[4]  <= "D"; tx_buf[5]  <= ":";
                    if(dir_up) begin
                        tx_buf[6]  <= "U"; tx_buf[7]  <= "P"; tx_buf[8]  <= " ";
                        tx_buf[9]  <= "M"; tx_buf[10] <= ":"; tx_buf[11] <= "A"; tx_buf[12] <= " ";
                        tx_buf[13] <= "D"; tx_buf[14] <= ":"; tx_buf[15] <= door_open ? "O" : "C";
                        tx_buf[16] <= 8'h0D; tx_buf[17] <= 8'h0A;  // 回车换行符\r\n
                        tx_total_len <= 5'd18;  // 本次回显一共18字节
                    end
                    else if(dir_down) begin
                        tx_buf[6]  <= "D"; tx_buf[7]  <= "O"; tx_buf[8]  <= "W"; tx_buf[9]  <= "N"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "A"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    else begin
                        tx_buf[6]  <= "S"; tx_buf[7]  <= "T"; tx_buf[8]  <= "O"; tx_buf[9]  <= "P"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "A"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    tx_req <= 1'b1;  // 指令匹配成功，发送请求
                end
                // MANUAL 指令匹配
                else if(rx_buf[0]=="M"&&rx_buf[1]=="A"&&rx_buf[2]=="N"&&rx_buf[3]=="U"&&rx_buf[4]=="A"&&rx_buf[5]=="L") begin
                    mode <= 4'b0010;
                    tx_buf[0]  <= "F"; tx_buf[1]  <= ":"; tx_buf[2]  <= 8'h30 + curr_floor; tx_buf[3]  <= " ";
                    tx_buf[4]  <= "D"; tx_buf[5]  <= ":";
                    if(dir_up) begin
                        tx_buf[6]  <= "U"; tx_buf[7]  <= "P"; tx_buf[8]  <= " ";
                        tx_buf[9]  <= "M"; tx_buf[10] <= ":"; tx_buf[11] <= "M"; tx_buf[12] <= " ";
                        tx_buf[13] <= "D"; tx_buf[14] <= ":"; tx_buf[15] <= door_open ? "O" : "C";
                        tx_buf[16] <= 8'h0D; tx_buf[17] <= 8'h0A;
                        tx_total_len <= 5'd18;
                    end
                    else if(dir_down) begin
                        tx_buf[6]  <= "D"; tx_buf[7]  <= "O"; tx_buf[8]  <= "W"; tx_buf[9]  <= "N"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "M"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    else begin
                        tx_buf[6]  <= "S"; tx_buf[7]  <= "T"; tx_buf[8]  <= "O"; tx_buf[9]  <= "P"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "M"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    tx_req <= 1'b1;
                end
                // FIRE 指令匹配
                else if(rx_buf[0]=="F"&&rx_buf[1]=="I"&&rx_buf[2]=="R"&&rx_buf[3]=="E") begin
                    mode <= 4'b0100;
                    tx_buf[0]  <= "F"; tx_buf[1]  <= ":"; tx_buf[2]  <= 8'h30 + curr_floor; tx_buf[3]  <= " ";
                    tx_buf[4]  <= "D"; tx_buf[5]  <= ":";
                    if(dir_up) begin
                        tx_buf[6]  <= "U"; tx_buf[7]  <= "P"; tx_buf[8]  <= " ";
                        tx_buf[9]  <= "M"; tx_buf[10] <= ":"; tx_buf[11] <= "F"; tx_buf[12] <= " ";
                        tx_buf[13] <= "D"; tx_buf[14] <= ":"; tx_buf[15] <= door_open ? "O" : "C";
                        tx_buf[16] <= 8'h0D; tx_buf[17] <= 8'h0A;
                        tx_total_len <= 5'd18;
                    end
                    else if(dir_down) begin
                        tx_buf[6]  <= "D"; tx_buf[7]  <= "O"; tx_buf[8]  <= "W"; tx_buf[9]  <= "N"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "F"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    else begin
                        tx_buf[6]  <= "S"; tx_buf[7]  <= "T"; tx_buf[8]  <= "O"; tx_buf[9]  <= "P"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "F"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    tx_req <= 1'b1;
                end
                // REPAIR 指令匹配
                else if(rx_buf[0]=="R"&&rx_buf[1]=="E"&&rx_buf[2]=="P"&&rx_buf[3]=="A"&&rx_buf[4]=="I"&&rx_buf[5]=="R") begin
                    mode <= 4'b1000;
                    tx_buf[0]  <= "F"; tx_buf[1]  <= ":"; tx_buf[2]  <= 8'h30 + curr_floor; tx_buf[3]  <= " ";
                    tx_buf[4]  <= "D"; tx_buf[5]  <= ":";
                    if(dir_up) begin
                        tx_buf[6]  <= "U"; tx_buf[7]  <= "P"; tx_buf[8]  <= " ";
                        tx_buf[9]  <= "M"; tx_buf[10] <= ":"; tx_buf[11] <= "R"; tx_buf[12] <= " ";
                        tx_buf[13] <= "D"; tx_buf[14] <= ":"; tx_buf[15] <= door_open ? "O" : "C";
                        tx_buf[16] <= 8'h0D; tx_buf[17] <= 8'h0A;
                        tx_total_len <= 5'd18;
                    end
                    else if(dir_down) begin
                        tx_buf[6]  <= "D"; tx_buf[7]  <= "O"; tx_buf[8]  <= "W"; tx_buf[9]  <= "N"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "R"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    else begin
                        tx_buf[6]  <= "S"; tx_buf[7]  <= "T"; tx_buf[8]  <= "O"; tx_buf[9]  <= "P"; tx_buf[10] <= " ";
                        tx_buf[11] <= "M"; tx_buf[12] <= ":"; tx_buf[13] <= "R"; tx_buf[14] <= " ";
                        tx_buf[15] <= "D"; tx_buf[16] <= ":"; tx_buf[17] <= door_open ? "O" : "C";
                        tx_buf[18] <= 8'h0D; tx_buf[19] <= 8'h0A;
                        tx_total_len <= 5'd20;
                    end
                    tx_req <= 1'b1;
                end
            end

            // 有发送请求则进入发送状态
            if(tx_req) begin
                comm_state  <= TX;
                tx_byte_cnt <= 5'd0;
                bit_cnt     <= 4'd0;
                baud_cnt    <= 16'd0;
            end
            // 检测到起始位下降沿，进入接收状态
            else if(uart_rx_sync2 == 1'b0) begin
                comm_state <= RX;
                baud_cnt   <= 16'd0;
                bit_cnt    <= 4'd0;
            end
        end

        // 接收时序 
        RX: begin
            baud_cnt <= baud_cnt + 16'd1;
            
            // 每个bit的中间位置采样
            if(baud_cnt == BAUD_CNT_MAX / 2) begin
                case(bit_cnt)
                    4'd0: begin
                        // 起始位中间：确认是低电平，否则认为是干扰，退回IDLE
                        if(uart_rx_sync2 != 1'b0) begin
                            comm_state <= IDLE;
                        end
                    end
                    4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8: begin
                        // 数据位0~7：依次存入rx_data
                        rx_data[bit_cnt - 4'd1] <= uart_rx_sync2;
                    end
                    4'd9: begin
                        // 停止位中间：确认是高电平，接收有效
                        if(uart_rx_sync2 == 1'b1) begin
                            // 过滤回车、换行符，不存入缓存，直接触发帧解析
                            if(rx_data == 8'h0D || rx_data == 8'h0A) begin
                                comm_state <= IDLE;
                                rx_len     <= 3'd0;
                                frame_done <= 1'b1;  // 拉高帧完成标志
                            end
                            else begin
                                // 普通字符存入缓存
                                if(rx_len < 3'd7) begin
                                    rx_buf[rx_len] <= rx_data;
                                    rx_len <= rx_len + 3'd1;
                                end
                                comm_state <= IDLE; // 收完一字节退回IDLE，等待下一字节
                            end
                        end
                        else begin
                            // 停止位错误，丢弃本次接收
                            comm_state <= IDLE;
                            rx_len <= 3'd0;
                        end
                    end
                endcase
            end

            // 每个波特周期结束，bit计数+1
            if(baud_cnt == BAUD_CNT_MAX) begin
                baud_cnt <= 16'd0;
                if(bit_cnt < 4'd9) begin
                    bit_cnt <= bit_cnt + 4'd1;
                end
            end
        end

        // 发送逻辑
        TX: begin
            baud_cnt <= baud_cnt + 16'd1;
				// 数满一个波特周期，就发下一位
            if(baud_cnt == BAUD_CNT_MAX) begin
                baud_cnt <= 16'd0;
                bit_cnt  <= bit_cnt + 4'd1;
                case(bit_cnt)
                    4'd0: uart_tx <= 1'b0;          // 第0位：拉低，发起始位
                    4'd1: uart_tx <= tx_buf[tx_byte_cnt][0];  // 发数据位第0位
                    4'd2: uart_tx <= tx_buf[tx_byte_cnt][1];
                    4'd3: uart_tx <= tx_buf[tx_byte_cnt][2];
                    4'd4: uart_tx <= tx_buf[tx_byte_cnt][3];
                    4'd5: uart_tx <= tx_buf[tx_byte_cnt][4];
                    4'd6: uart_tx <= tx_buf[tx_byte_cnt][5];
                    4'd7: uart_tx <= tx_buf[tx_byte_cnt][6];
                    4'd8: uart_tx <= tx_buf[tx_byte_cnt][7];  // 发数据位第7位
                    4'd9: begin
                        uart_tx <= 1'b1;          // 第9位：拉高，发停止位
								// 判断还有没有下一个字节要发
                        if(tx_byte_cnt < tx_total_len - 1) begin
                            tx_byte_cnt <= tx_byte_cnt + 5'd1;
                            bit_cnt <= 4'd0;  // 位计数清零，发下一字节
                        end
                        else begin
                            comm_state <= IDLE;  // 全部发完，退回空闲
                            tx_req <= 1'b0;
                        end
                    end
                    default: uart_tx <= 1'b1;
                endcase
            end
        end
        default: comm_state <= IDLE;
        endcase
    end
end

endmodule