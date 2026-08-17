`timescale 1ns/1ns

module key_debounce_tb;

// 定义激励信号和观测信号
reg        clk;     
reg        rst_n;  
reg  [7:0] key_in;  
wire [7:0] key_out;

// 实例化待测试模块，重定义消抖计数值最大为10，加速仿真
key_debounce #(
	.CNT_MAX(9)
) u_key_debounce(
	.clk(clk),
	.rst_n(rst_n),
	.key_in(key_in),
	.key_out(key_out)
);

// 生成时钟
initial begin
	clk = 1'b0;
	forever #10 clk = ~clk;
end

// 测试激励
initial begin
	rst_n = 1'b0;
	key_in = 8'hff;
	#200;
	rst_n = 1'b1; 
	
	// 模拟按键0按下时的抖动
	#100 key_in[0] = 1'b0;
	#20  key_in[0] = 1'b1;
	#35  key_in[0] = 1'b0;
	#10  key_in[0] = 1'b1;
	#40  key_in[0] = 1'b0;  // 之后稳定按下，低电平
	
	// 等待消抖完成，观察key_out是否变低
	#200;
	
	// 模拟按键0松开时的抖动
	#100 key_in[0] = 1'b1;
	#30  key_in[0] = 1'b0;
	#20  key_in[0] = 1'b1;
	#25  key_in[0] = 1'b0;
	#40  key_in[0] = 1'b1;  // 之后稳定松开，高电平
	
	// 等待消抖完成，观察key_out是否变高
	#300;
	
	$stop;
end

endmodule