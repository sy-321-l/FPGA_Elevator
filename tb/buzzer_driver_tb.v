`timescale 1ns/1ns

module buzzer_driver_tb;

reg    clk;
reg    rst_n;
reg    trig;
wire   buzzer_out;

// 实例化DUT，重定义计数最大值为9，共10个周期响铃
buzzer_driver #(
    .BUZZER_CNT(9)
) u_buzzer_driver (
    .clk(clk),
	 .rst_n(rst_n),
	 .trig(trig),
	 .buzzer_out(buzzer_out)
);

// 生成50MHz时钟，周期20ns
initial begin
    clk = 1'b0;
	 forever #10 clk = ~clk;
end

// 测试激励
initial begin
    rst_n = 1'b0;
	 trig = 1'b0;
	 #200;
	 rst_n = 1'b1;
	 
	 //场景1：持续高电平只触发一次，时长固定
	 #100;
	 trig = 1'b1;
	 #200;  // 持续200ns
	 trig = 1'b0;
	 // 等待蜂鸣器结束
	 #300;
	 
	 // 场景2：窄毛刺不会误触发
	 #100;
	 #3 trig = 1'b1;  // 不对齐时钟沿，模拟异步毛刺
	 #10 trig = 1'b0;
	 #200;
	 
	 // 场景3：正常单脉冲触发功能正常
	 #100;
	 @(posedge clk);  // 对齐时钟沿
	 trig = 1'b1;
	 @(posedge clk);
	 trig = 1'b0;
	 // 等待蜂鸣器响完
	 #300;
	 $stop;
end

endmodule