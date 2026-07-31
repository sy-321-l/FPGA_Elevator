module call_schedule
(
    input               clk,
    input               rst_n,
    input       [2:0]   curr_floor,     // 当前楼层 1~6
    input               dir_up,         // 1=电梯上行
    input               dir_down,       // 1=电梯下行
    input       [5:0]   call_req,       // 呼叫输入，低有效
    output reg  [2:0]   target_floor,    // 电梯目标楼层
    output              has_call        // 是否存在未处理呼叫
);

reg [5:0] call_reg; // 呼叫锁存寄存器

// 组合逻辑实时判断有无呼叫，消除时序延迟
assign has_call = (call_reg != 6'b111111);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        call_reg    <= 6'b111111;
        target_floor<= 3'd1;
    end
    else begin
        // 1、更新呼叫寄存：到达目标楼层则清除该层请求
        if(target_floor == curr_floor && has_call) begin
            call_reg[target_floor - 1'b1] <= 1'b1;
        end
        else begin
            call_reg <= call_reg & call_req;
        end

        // 2、标准集选调度逻辑
        if(!has_call) begin
            target_floor <= curr_floor; // 无呼叫，停原地
        end
        // 分支1：电梯上行
        else if(dir_up) begin
            // 先查找当前楼层以上、最高的呼叫
            if(call_reg[5]==0 && 6 > curr_floor)      target_floor <= 3'd6;
            else if(call_reg[4]==0 && 5 > curr_floor) target_floor <= 3'd5;
            else if(call_reg[3]==0 && 4 > curr_floor) target_floor <= 3'd4;
            else if(call_reg[2]==0 && 3 > curr_floor) target_floor <= 3'd3;
            else if(call_reg[1]==0 && 2 > curr_floor) target_floor <= 3'd2;
            // 当前楼层上方无呼叫，遍历全部楼层处理下方请求
            else begin
                if(call_reg[5]==0)      target_floor <= 3'd6;
                else if(call_reg[4]==0) target_floor <= 3'd5;
                else if(call_reg[3]==0) target_floor <= 3'd4;
                else if(call_reg[2]==0) target_floor <= 3'd3;
                else if(call_reg[1]==0) target_floor <= 3'd2;
                else if(call_reg[0]==0) target_floor <= 3'd1;
            end
        end
        // 分支2：电梯下行
        else if(dir_down) begin
            // 先查找当前楼层以下、最高的呼叫（顺路优先高层）
            if(call_reg[4]==0 && 5 < curr_floor)      target_floor <= 3'd5;
            else if(call_reg[3]==0 && 4 < curr_floor) target_floor <= 3'd4;
            else if(call_reg[2]==0 && 3 < curr_floor) target_floor <= 3'd3;
            else if(call_reg[1]==0 && 2 < curr_floor) target_floor <= 3'd2;
            else if(call_reg[0]==0 && 1 < curr_floor) target_floor <= 3'd1;
            // 当前楼层下方无呼叫，遍历全部楼层处理上方请求
            else begin
                if(call_reg[5]==0)      target_floor <= 3'd6;
                else if(call_reg[4]==0) target_floor <= 3'd5;
                else if(call_reg[3]==0) target_floor <= 3'd4;
                else if(call_reg[2]==0) target_floor <= 3'd3;
                else if(call_reg[1]==0) target_floor <= 3'd2;
                else if(call_reg[0]==0) target_floor <= 3'd1;
            end
        end
        // 分支3：电梯静止无运行方向，直接去全局最高呼叫楼层
        else begin
            if(call_reg[5]==0)      target_floor <= 3'd6;
            else if(call_reg[4]==0) target_floor <= 3'd5;
            else if(call_reg[3]==0) target_floor <= 3'd4;
            else if(call_reg[2]==0) target_floor <= 3'd3;
            else if(call_reg[1]==0) target_floor <= 3'd2;
            else if(call_reg[0]==0) target_floor <= 3'd1;
        end
    end
end

endmodule