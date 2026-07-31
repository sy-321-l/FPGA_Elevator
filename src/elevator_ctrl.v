module elevator_ctrl
(
    input               clk,
    input               rst_n,
    // 来自楼层检测模块 floor_detect
    input       [2:0]   curr_floor,
    // 来自呼梯调度模块 call_schedule
    input       [2:0]   target_floor,
    input               has_call,
    // 消抖后门控按键 (来自key_debounce输出拆分)
    input               key_open,  // key_out[7] 低电平按下有效
    input               key_close,// key_out[6] 低电平按下有效
    // 串口输出运行模式 4bit
    input       [3:0]   mode,
    // 输出：回传给呼梯调度
    output  reg         dir_up,
    output  reg         dir_down,
    // 输出：门状态，给LED显示模块
    output  reg         door_open,
    // 输出：蜂鸣触发，给buzzer_driver
    output  reg         beep_trig
);

// 模式编码
localparam NORMAL_MODE  = 4'b0001;  // 自动
localparam MANUAL_MODE  = 4'b0010;  // 手动
localparam FIRE_MODE    = 4'b0100;  // 消防，最高优先级
localparam REPAIR_MODE  = 4'b1000;  // 检修

// 电梯运行状态编码
localparam IDLE    = 4'd0;  // 空闲
localparam UP      = 4'd1;  // 上行
localparam DOWN    = 4'd2;  // 下行
localparam ARRIVE  = 4'd3;  // 到站停顿
localparam OPEN    = 4'd4;  // 开门
localparam CLOSE   = 4'd5;  // 关门延时

reg [3:0] curr_state;
reg [3:0] next_state;

// 50MHz系统时钟，1s计数最大值 49,999,999
parameter ONE_SEC_MAX = 26'd49_999_999;
reg [25:0] cnt_1s;    // 通用1秒计时器
reg        cnt_en;    // 计时使能
reg [1:0]  door_cnt;  // 开门计时0~3秒

// 1秒通用计时器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_1s <= 26'd0;
    else if(cnt_en) begin
        if(cnt_1s == ONE_SEC_MAX)
            cnt_1s <= 26'd0;
        else
            cnt_1s <= cnt_1s + 26'd1;
    end
    else
        cnt_1s <= 26'd0;
end

// 状态寄存器时序逻辑 (两段式FSM)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        curr_state <= IDLE;
    else
        curr_state <= next_state;
end

// 组合逻辑：状态跳转（最高优先级特殊模式）
always @(*) begin
    next_state = curr_state;  // 默认保持，防止组合逻辑锁存
    // 最高优先级：消防模式（覆盖所有其他状态）
    if(mode & FIRE_MODE) begin
        if(curr_floor == 3'd1)
            next_state = OPEN;
        else
            next_state = DOWN;
    end
    // 次高优先级：检修模式
    else if(mode & REPAIR_MODE) begin
        next_state = IDLE;
    end
    // 自动/手动正常模式运行状态
    else begin
        case(curr_state)
            IDLE: begin
                if(mode & MANUAL_MODE) begin
                    // 手动模式：无自动跑梯，仅按键开门
                    if(!key_open) next_state = OPEN;
                    else next_state = IDLE;
                end
                else begin
                    // 自动模式：有呼梯自动上下行，无呼叫可手动开门
                    if(has_call && target_floor > curr_floor)
                        next_state = UP;
                    else if(has_call && target_floor < curr_floor)
                        next_state = DOWN;
                    else if(!key_open)
                        next_state = OPEN;
                    else
                        next_state = IDLE;
                end
            end

            UP: begin
                // 上行运行中屏蔽开门按键，到达目标楼层切到站
                if(curr_floor == target_floor)
                    next_state = ARRIVE;
                else
                    next_state = UP;
            end

            DOWN: begin
                // 下行运行中屏蔽开门按键，到达目标楼层切到站
                if(curr_floor == target_floor)
                    next_state = ARRIVE;
                else
                    next_state = DOWN;
            end

            ARRIVE: begin
                // 到站蜂鸣，1秒后自动开门
                if(cnt_1s == ONE_SEC_MAX)
                    next_state = OPEN;
                else
                    next_state = ARRIVE;
            end

            OPEN: begin
                // 开门状态：按关门键立即关门；满3秒自动关门
                if(!key_close)
                    next_state = CLOSE;
                else if(door_cnt == 2'd3 && cnt_1s == ONE_SEC_MAX)
                    next_state = CLOSE;
                else
                    next_state = OPEN;
            end

            CLOSE: begin
                // 关门延时1秒返回空闲
                if(cnt_1s == ONE_SEC_MAX)
                    next_state = IDLE;
                else
                    next_state = CLOSE;
            end

            default: next_state = IDLE;
        endcase
    end
end

// 时序输出：方向、门、蜂鸣、计时 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dir_up     <= 1'b0;
        dir_down   <= 1'b0;
        door_open  <= 1'b0;
        beep_trig  <= 1'b0;
        cnt_en     <= 1'b0;
        door_cnt   <= 2'd0;
    end
    else begin
        // 默认赋值防止锁存
        dir_up     <= 1'b0;
        dir_down   <= 1'b0;
        door_open  <= 1'b0;
        beep_trig  <= 1'b0;
        cnt_en     <= 1'b0;
        door_cnt   <= door_cnt;

        case(curr_state)
            IDLE: begin
                door_open <= 1'b0;
                cnt_en    <= 1'b0;
                door_cnt  <= 2'd0; // 空闲清零开门计时
            end

            UP: begin
                dir_up    <= 1'b1;
                dir_down  <= 1'b0;
                door_open <= 1'b0; // 运行门关死
                cnt_en    <= 1'b1;
                door_cnt  <= 2'd0;
            end

            DOWN: begin
                dir_up    <= 1'b0;
                dir_down  <= 1'b1;
                door_open <= 1'b0; // 运行门关死
                cnt_en    <= 1'b1;
                door_cnt  <= 2'd0;
            end

            ARRIVE: begin
                beep_trig <= 1'b1; // 到站触发蜂鸣器
                cnt_en    <= 1'b1;
                door_cnt  <= 2'd0; // 到站重置开门计时
            end

            OPEN: begin
                door_open <= 1'b1;
                cnt_en    <= 1'b1;
                // 每满1秒开门计数+1，实现3秒保持
                if(cnt_1s == ONE_SEC_MAX)
                    door_cnt <= door_cnt + 2'd1;
            end

            CLOSE: begin
                door_open <= 1'b0;
                cnt_en    <= 1'b1;
                door_cnt  <= 2'd0; // 关门清零计时
            end
        endcase

        // 消防模式强制输出：未到1楼持续下行，到1楼永久开门
        if(mode & FIRE_MODE) begin
            if(curr_floor != 3'd1) begin
                dir_down  <= 1'b1;
                door_open <= 1'b0;
            end
            else begin
                dir_up    <= 1'b0;
                dir_down  <= 1'b0;
                door_open <= 1'b1;
            end
        end
    end
end

endmodule