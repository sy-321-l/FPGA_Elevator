`timescale 1ns/1ns

module call_schedule_tb;

reg clk;
reg rst_n;
reg [2:0] curr_floor;
reg dir_up;
reg dir_down;
reg [5:0] call_req;

wire [2:0] target_floor;
wire has_call;

call_schedule u_call_schedule(
    .clk(clk),
	 .rst_n(rst_n),
	 .curr_floor(curr_floor),
	 .dir_up(dir_up),
	 .dir_down(dir_down),
	 .call_req(call_req),
	 .target_floor(target_floor),
	 .has_call(has_call)
);

initial begin
    clk = 1'b0;
	 forever #10 clk = ~clk;
end

initial begin
    // 复位初始化
	 rst_n = 1'b0;
	 curr_floor = 3'd1;
	 dir_up = 1'b0;
	 dir_down = 1'b0;
	 call_req = 6'b111111;
	 #200;
	 rst_n = 1'b1;
	 #35;
	 
	 // 场景1：静止1楼，呼叫3、6楼
	 call_req = 6'h1b;  // 011011
	 #115;
	 call_req = 6'h3f;
	 #200;
	 
	 // 场景2：上行前往6楼，到达后清除6楼，剩余3楼请求
	 #15;
	 dir_up = 1'b1;
	 curr_floor = 3'd2; #100;
	 curr_floor = 3'd3; #100;
	 curr_floor = 3'd4; #100;
	 curr_floor = 3'd5; #100;
	 curr_floor = 3'd6; #200;
	 #15;
	 dir_up = 1'b0;
	 #200;
	 
	 // 场景3: 6楼下行，呼叫4、2楼
	 #15;
	 dir_down = 1'b1;
	 call_req = 6'h35;  // 110101
	 #115;
	 call_req = 6'h3f;
	 curr_floor = 3'd5; #100;
	 curr_floor = 3'd4; #200;  // 抵达4层，清4呼叫，target切3
	 curr_floor = 3'd3; #200;  // 下到3层，清3呼叫，target切2
	 curr_floor = 3'd2; #200;  // 下到2层，清2呼叫，无请求
	 #15;
	 dir_down = 1'b0;
	 #300;
	 $stop;
end

endmodule