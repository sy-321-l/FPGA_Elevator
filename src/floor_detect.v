module floor_detect(
	input            clk,
	input            rst_n,
	input      [5:0] sw_floor,   // 拨码开关，闭合=0，断开=1
	output reg [2:0] curr_floor  // 当前楼层1-6
);

// 两级同步寄存器
reg [5:0] sw_sync1, sw_sync2;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sw_sync1 <= 6'h3f;
		sw_sync2 <= 6'h3f;
	end
	else begin
		sw_sync1 <= sw_floor;
		sw_sync2 <= sw_sync1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		curr_floor <= 3'd1;  // 复位默认1楼
	else begin
		case(sw_sync2)
			6'b111110: curr_floor <= 3'd1;
			6'b111101: curr_floor <= 3'd2;
			6'b111011: curr_floor <= 3'd3;
			6'b110111: curr_floor <= 3'd4;
			6'b101111: curr_floor <= 3'd5;
			6'b011111: curr_floor <= 3'd6;
			default: curr_floor <= curr_floor;  // 多开关闭合/断开，保持楼层
		endcase
	end
end

endmodule