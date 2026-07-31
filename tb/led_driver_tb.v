`timescale 1ns/1ns
module led_driver_tb;

reg       clk;
reg       rst_n;
reg [2:0] curr_floor;
reg       dir_up;
reg       dir_down;
reg [3:0] mode;

wire [5:0] led_floor;
wire [1:0] led_dir;
wire [3:0] led_mode;

led_driver u_led_driver(
    .clk(clk),
	 .rst_n(rst_n),
	 .curr_floor(curr_floor),
	 .dir_up(dir_up),
	 .dir_down(dir_down),
	 .mode(mode),
	 .led_floor(led_floor),
	 .led_dir(led_dir),
	 .led_mode(led_mode)
);

initial begin
    clk = 1'b0;
	 forever #10 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
	 curr_floor = 3'd1;
	 dir_up = 1'b0;
	 dir_down = 1'b0;
	 mode = 4'b0001;
	 #200;
	 rst_n = 1'b1;
	 #20;
	 
	 // 场景1: 1楼，自动模式，上行
	 curr_floor = 3'd1;
	 dir_up = 1'b1;
	 dir_down = 1'b0;
	 mode = 4'b0001;
	 #40;
	 
	 // 场景2：3楼，手动模式，静止
	 curr_floor = 3'd3;
	 dir_up = 1'b0;
	 dir_down = 1'b0;
	 mode = 4'b0010;
	 #40;
	 
	 // 场景3：6楼，消防模式，下行
	 curr_floor = 3'd6;
	 dir_up = 1'b0;
	 dir_down = 1'b1;
	 mode = 4'b0100;
	 #40;
	 
	 // 场景4：4楼，检修模式，上下行同时置1
	 curr_floor = 3'd4;
	 dir_up = 1'b1;
	 dir_down = 1'b1;
	 mode = 4'b1000;
	 #40;
	 
	 // 场景5：2楼，异常楼层输入，检验default默认1楼灯亮
	 curr_floor = 3'd7;
	 dir_up = 1'b0;
	 dir_down = 1'b0;
	 mode = 4'b0001;
	 #40;
	 
	 // 场景6：5楼，自动模式，下行
	 curr_floor = 3'd5;
	 dir_up = 1'b0;
	 dir_down = 1'b1;
	 mode = 4'b0001;
	 #40;
	 
	 #200;
	 $stop;
end

endmodule