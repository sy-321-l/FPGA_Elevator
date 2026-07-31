module key_debounce
(
    input               clk,       // 50MHz系统时钟
	 input               rst_n,     // 复位，低电平有效
	 input        [7:0]  key_in,    // 8路按键输入：按下=低电平，松开=高电平
	 output  reg  [7:0]  key_out    // 消抖后稳定输出
);

parameter CNT_MAX = 20'd999_999;   // 20ms消抖时长

reg [19:0] cnt;                    // 20位计数器，最大数到104万
reg [7:0] key_sync1, key_sync2;    // 两级同步寄存器，避免亚稳态

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
	     key_sync1 <= 8'hff;        // 复位默认按键全部松开
		  key_sync2 <= 8'hff;
	 end
	 else begin
	     key_sync1 <= key_in;       // 第一拍采样
		  key_sync2 <= key_sync1;    // 第二拍打拍
	 end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
	     cnt <= 20'd0;
		  key_out <= 8'hff;
	 end
	 else if(key_sync2 != key_out) begin  // 检测到按键电平变化，开始消抖计时
	     if(cnt < CNT_MAX) begin
		      cnt <= cnt + 20'd1;          // 没计满20ms，继续加1
		  end
		  else begin
		      cnt <= 20'd0;                // 计满后清零，准备下次消抖
				key_out <= key_sync2;        // 确认电平稳定，更新输出
		  end
	 end
	 else begin
	     cnt <= 20'd0;  // 电平没变化/抖动回去了，计数器清零
	 end
end

endmodule