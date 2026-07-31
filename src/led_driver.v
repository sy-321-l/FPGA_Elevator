module led_driver
(
    input       clk,
	 input       rst_n,
	 input [2:0] curr_floor,
	 input       dir_up,
	 input       dir_down,
	 input [3:0] mode,
	 output reg [5:0] led_floor,  // 6个楼层LED，高电平点亮
	 output reg [1:0] led_dir,    // 2个方向LED：[0]上行，[1]下行
	 output reg [3:0] led_mode    // 4个模式LED
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
	     led_floor <= 6'b000001;  // 复位默认1楼点亮
		  led_dir   <= 2'd0;       // 复位方向灯全灭
		  led_mode  <= 4'b0001;    // 复位默认自动模式
	 end
	 else begin
	     case(curr_floor)
		      3'd1: led_floor <= 6'b000001;
				3'd2: led_floor <= 6'b000010;
				3'd3: led_floor <= 6'b000100;
				3'd4: led_floor <= 6'b001000;
				3'd5: led_floor <= 6'b010000;
				3'd6: led_floor <= 6'b100000;
			   default: led_floor <= 6'b000001;
		  endcase
	     
		  // 方向指示
		  led_dir[0] <= dir_up;
	     led_dir[1] <= dir_down;
		  
		  led_mode <= mode;  // 模式指示
	 end
end

endmodule