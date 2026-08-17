`timescale 1ns/1ns

module floor_detect_tb;

reg        clk;
reg        rst_n;
reg  [5:0] sw_floor;
wire [2:0] curr_floor;

floor_detect u_floor_detect(
	.clk(clk),
	.rst_n(rst_n),
	.sw_floor(sw_floor),
	.curr_floor(curr_floor)
);

initial begin
	clk = 1'b0;
	forever #10 clk = ~clk;
end

initial begin
	rst_n = 1'b0;
	sw_floor = 6'b111111;  // 全部开关断开
	#200;
	rst_n = 1'b1;
	#40;
	
	// 1-6楼依次切换
	sw_floor = 6'b111110;  #60;
	sw_floor = 6'b111101;  #60;
	sw_floor = 6'b111011;  #60;
	sw_floor = 6'b110111;  #60;
	sw_floor = 6'b101111;  #60;
	sw_floor = 6'b011111;  #60;
	
	// 同时闭合1、6楼开关
	sw_floor = 6'b011110;  #60;
	// 全部开关断开
	sw_floor = 6'b111111;  #60;
	
	$stop;
end

endmodule