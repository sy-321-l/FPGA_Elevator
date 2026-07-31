module elevator_top
(
    input         clk,
	 input         rst_n,
	 input  [7:0]  key_in,    // 物理按键输入，8bit
	 input  [5:0]  sw_floor,  // 楼层拨码开关输入，6bit
	 input         uart_rx,
	 output        uart_tx,
	 output        buzzer_out,
	 output [5:0]  led_floor,
	 output [1:0]  led_dir,
	 output [3:0]  led_mode
);

// 内部互联信号
wire [7:0] key_stable;
wire [5:0] call_req;
wire key_open, key_close;

wire [2:0] curr_floor;
wire [2:0] target_floor;
wire has_call;
wire dir_up, dir_down;

wire [3:0] mode;
wire door_open;
wire beep_trig;

// 按键消抖模块
key_debounce u_key_filter
(
    .clk(clk),
	 .rst_n(rst_n),
	 .key_in(key_in),
	 .key_out(key_stable)
);
assign call_req  = key_stable[5:0];
assign key_open  = key_stable[7];
assign key_close = key_stable[6];

// 楼层检测模块
floor_detect u_floor_sensor
(
    .clk(clk),
	 .rst_n(rst_n),
	 .sw_floor(sw_floor),
	 .curr_floor(curr_floor)
);

// 呼梯调度模块
call_schedule u_schedule
(
    .clk(clk),
	 .rst_n(rst_n),
	 .curr_floor(curr_floor),
	 .dir_up(dir_up),
	 .dir_down(dir_down),
	 .call_req(call_req),
	 .target_floor(target_floor),
	 .has_call(has_call)
);

// 电梯核心状态机
elevator_ctrl u_elevator_core
(
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

// 蜂鸣器驱动
buzzer_driver u_buzzer
(
    .clk(clk),
	 .rst_n(rst_n),
	 .trig(beep_trig),
	 .buzzer_out(buzzer_out)
);

// LED显示驱动
led_driver u_led
(
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

// 串口收发指令解析
uart_mode_comm u_uart_comm
(
    .clk(clk),
	 .rst_n(rst_n),
	 .uart_rx(uart_rx),
	 .uart_tx(uart_tx),
	 .curr_floor(curr_floor),
	 .dir_up(dir_up),
	 .dir_down(dir_down),
	 .door_open(door_open),
	 .mode(mode)
);

endmodule