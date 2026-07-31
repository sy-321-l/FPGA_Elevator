`timescale 1ns/1ns  // 时间单位/精度/：1纳秒

module key_debounce_tb;

// 定义激励信号和观测信号 
reg         clk;      // 系统时钟
reg         rst_n;    // 复位，低电平有效
reg  [7:0]  key_in;   // 按键输入，低电平有效
wire [7:0]  key_out;  // 消抖后输出

// 实例化待测试模块，重定义消抖计数最大值为10，加速仿真
key_debounce #(
    .CNT_MAX(10)
) u_key_debounce (
    .clk     (clk),
	 .rst_n   (rst_n),
	 .key_in  (key_in),
	 .key_out (key_out)
);

// 生成50MHz系统时钟：周期20ns，高低各10ns
initial begin
    clk = 1'b0;
	 forever #10 clk = ~clk;
end

// 测试激励
initial begin
    rst_n = 1'b0;    // 先复位
	 key_in = 8'hff;  // 按键全部松开
	 #200;            // 复位持续200ns
	 rst_n = 1'b1;    // 复位结束，系统开始工作
	 
	 // 模拟按键0按下时的抖动
	 #100  key_in[0] = 1'b0;
	 #20   key_in[0] = 1'b1;
	 #30   key_in[0] = 1'b0;
	 #15   key_in[0] = 1'b1;
	 #40   key_in[0] = 1'b0;  // 之后稳定按下，低电平
	 
	 // 等待消抖完成，观察key_out是否变低
	 #200;
	 
	 // 模拟按键0松开时的抖动
	 #100  key_in[0] = 1'b1;
	 #25   key_in[0] = 1'b0;
	 #20   key_in[0] = 1'b1;
	 #35   key_in[0] = 1'b0;
	 #30   key_in[0] = 1'b1;  // 之后稳定松开，高电平
	 
	 // 等待消抖完成，观察key_out是否变高
	 #300;
	 
	 $stop;  // 停止仿真
end

endmodule