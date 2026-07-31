`timescale 1ns/1ns

module floor_detect_tb;

reg         clk;
reg         rst_n;
reg  [5:0]  sw_floor;
wire [2:0]  curr_floor;

// 实例化DUT
floor_detect u_floor_detect(
    .clk(clk),
	 .rst_n(rst_n),
	 .sw_floor(sw_floor),
	 .curr_floor(curr_floor)
);

// 50MHz时钟，周期20ns
initial begin
    clk = 1'b0;
	 forever #10 clk = ~clk;
end

// 测试激励
initial begin
    rst_n = 1'b0;
	 sw_floor = 6'b111111;  //全部开关断开
	 #200;
	 
	 // 释放复位，默认1楼
	 rst_n = 1'b1;
	 #30;
	 
	 // 1-6楼依次切换，每个场景停留50ns
	 sw_floor = 6'b111110;  #50;
	 sw_floor = 6'b111101;  #50;
	 sw_floor = 6'b111011;  #50;
	 sw_floor = 6'b110111;  #50;
	 sw_floor = 6'b101111;  #50;
	 sw_floor = 6'b011111;  #50;
	 
	 // 同时闭合1、6楼开关
	 sw_floor = 6'b011110;  #50;
	 // 全部开关断开
	 sw_floor = 6'b111111;  #50;
	 
	 $stop;
end

endmodule