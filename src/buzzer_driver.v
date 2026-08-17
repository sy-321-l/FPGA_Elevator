module buzzer_driver(
	input      clk,
	input      rst_n,
	input      trig,       // 触发信号，输入高电平有效
	output reg buzzer_out  // 蜂鸣器输出，高电平发声
);

parameter BUZZER_CNT = 25'd24_999_999;  // 0.5秒计时

reg [24:0] cnt;
reg buzzer_en;  // 蜂鸣器使能标志

// 两级同步寄存器
reg trig_sync1, trig_sync2;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		trig_sync1 <= 1'b0;
		trig_sync2 <= 1'b0;
	end
	else begin
		trig_sync1 <= trig;
		trig_sync2 <= trig_sync1;
	end
end

// 上升沿检测，生成单脉冲触发
reg trig_dly;  // 寄存一拍同步后的信号
wire trig_pulse;  // 最终的单周期触发脉冲
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		trig_dly <= 1'b0;
	else
		trig_dly <= trig_sync2;
end

assign trig_pulse = trig_sync2 & (~trig_dly);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 25'd0;
		buzzer_en <= 1'b0;
	end
	else if(trig_pulse) begin
		// 启动蜂鸣，重装计数器
		buzzer_en <= 1'b1;
		cnt <= BUZZER_CNT;
	end
	else if(buzzer_en) begin
		// 蜂鸣倒计时
		if(cnt > 25'd0)
			cnt <= cnt - 25'd1;
		else
			buzzer_en <= 1'b0;  // 计数归零，停止蜂鸣
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		buzzer_out <= 1'b0;
	else
		buzzer_out <= buzzer_en;
end

endmodule