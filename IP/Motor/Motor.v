`timescale 1ns / 1ps
/*
입력 :  Pulse 수
        모터 속도
        방향
        Hold off
        Motor Start / Stop (ENMCKA - Interlock)

출력 :  현재 Pulse
        동작
*/

module Motor
(
    input i_fRST,
    input i_clk,

    // Zynq Ports
    output o_motor_step,

    // AXI
    input [31:0] i_step_cnt,
    input [31:0] i_motor_speed,
    input i_motor_run,

    output [31:0] o_step_cnt,
    output o_motor_run
);

    // state machine
    parameter idle = 0;
    parameter motor_set = 1;
    parameter motor_run = 2;

    reg [1:0] state;
    reg [1:0] n_state;

    // Time Counter
    reg [1:0] motor_run_cnt;
    reg [31:0] motor_speed_cnt;

    // flag
    wire motor_run_flag;
    wire motor_step_flag;

    // Data
    reg [31:0] step_cnt;
    reg [31:0] motor_speed;

    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            state <= idle;

        else 
            state <= n_state;
    end

    // state machince
    always @(*)
    begin
        case (state)
            idle :
            begin
                if (motor_run_flag)
                    n_state <= motor_set;

                else
                    n_state <= idle;
            end

            motor_set :
                    n_state <= motor_run;

            motor_run :
            begin
                if (step_cnt == 0)            
                    n_state <= idle;
                
                else
                    n_state <= motor_run;
            end

            default :
                    n_state <= idle;
        endcase
    end

    // 
    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            motor_run_cnt <= 0;

        else if ((i_motor_run) && (motor_run_cnt < 3))
            motor_run_cnt <= motor_run_cnt + 1;

        else if (~i_motor_run)
            motor_run_cnt <= 0;

        else
            motor_run_cnt <= motor_run_cnt;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            motor_speed <= 0;

        else if (state == motor_set)
        begin
            if (i_motor_speed > 2000)
                motor_speed <= i_motor_speed;

            else
                motor_speed <= 2000;
        end

        else
            motor_speed <= motor_speed;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            step_cnt <= 0;

        else if (state == motor_set)
            step_cnt <= i_step_cnt;

        else if (state == motor_run)
        begin
            if (motor_step_flag)
                step_cnt <= step_cnt - 1;

            else
                step_cnt <= step_cnt;
        end

        else
            step_cnt <= step_cnt;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            motor_speed_cnt <= 0;

        else if (state == motor_run)
        begin
            if (motor_speed_cnt == motor_speed)
                motor_speed_cnt <= 0;
            
            else
                motor_speed_cnt <= motor_speed_cnt + 1;
        end

        else
            motor_speed_cnt <= 0;
    end


    assign motor_run_flag = (motor_run_cnt == 1) ? 1 : 0;
    assign o_motor_step = (motor_speed_cnt < (motor_speed / 2)) ? 1 : 0;
    assign motor_step_flag = (motor_speed_cnt == motor_speed) ? 1 : 0;
    assign o_step_cnt = step_cnt;
    assign o_motor_run = (state == motor_run) ? 1 : 0;

endmodule