`timescale 1ns/1ns
module elevator_ctrl_tb;

reg       clk;
reg       rst_n;
reg [2:0] curr_floor;
reg [2:0] target_floor;
reg       has_call;
reg       key_open;
reg       key_close;
reg [3:0] mode;

wire      dir_up;
wire      dir_down;
wire      door_open;
wire      beep_trig;

elevator_ctrl u_elevator_ctrl(
    .clk(clk),
	 .rst_n(rst_n),
	 .curr_floor(curr_floor),
	 .target_floor(target_floor),
	 .has_call(has_call),
	 .key_open(key_open),
	 .key_close(key_close),
	 .mode(mode),
	 .dir_up(dir_up),
	 .dir_down(dir_down),
	 .door_open(door_open),
	 .beep_trig(beep_trig)
);

initial begin
    clk = 1'b0;
	 forever #10 clk = ~clk;
end

initial begin
    // 复位初始化
	 rst_n        = 1'b0;
	 curr_floor   = 3'd1;
	 target_floor = 3'd1;
	 has_call     = 1'b0;
	 key_open     = 1'b1;
	 key_close    = 1'b1;
	 mode         = 4'b0001;
	 #100;
	 rst_n = 1'b1;
	 #40;
	 
	 // 场景1：自动模式 1->6 上行
	 $display("场景1：1楼呼叫6楼上行");
	 target_floor = 3'd6;
	 has_call     = 1'b1;
	 #200;
	 curr_floor   = 3'd6;  // 手动模拟到达6楼，跳过长计时
	 #300;
	 has_call     = 1'b0;
	 #100;
	 
	 // 场景2：自动模式 6->2 下行，手动关门
	 $display("场景2：6楼呼叫2楼下行");
	 target_floor = 3'd2;
	 has_call     = 1'b1;
	 #200;
	 curr_floor   = 3'd2;
	 #100;
	 key_close    = 1'b0;
	 #40;
	 key_close    = 1'b1;
	 #200;
	 has_call     = 1'b0;
	 #100;
	
    // 场景3：手动模式，仅手动开关门
	 $display("场景3：手动模式");
	 mode         = 4'b0010;
	 #40;
	 key_open     = 1'b0; 
	 #200;
	 key_open     = 1'b1;
	 key_close    = 1'b0;
	 #200;
	 key_close    = 1'b1;
	 #100;
	 
	 // 场景4：消防模式强制回1楼
	 $display("场景4：消防模式");
	 mode         = 4'b0100;
	 curr_floor   = 3'd4;
	 #200;
	 curr_floor   = 3'd1;
	 #200;
	 mode         = 4'b0001;
	 #100;
	 
	 // 场景5：检修模式
	 $display("场景5：检修模式");
	 mode         = 4'b1000;
	 #40;
	 key_open     = 1'b0;
	 #200;
	 key_open     = 1'b1;
	 #100;
	 mode         = 4'b0001;
	 #100;
	 
	 $stop;
end

endmodule