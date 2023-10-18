`timescale 1ns / 1ps
/*

*/

module DAC_DAC8563 #
(
    parameter integer DATA_WIDTH = 24              // SPI Data 크기
)
(
    input i_fRST,
    input i_clk,

    // ZYNQ Ports
    output o_dac_trg_led_A,
    output o_dac_trg_led_B,

    // SPI
    input [2:0] i_spi_state,
    
    output o_spi_start,
    output reg [DATA_WIDTH - 1 : 0] o_spi_data,

    // AXI
    input [DATA_WIDTH - 1:0] i_dac_data,
    input i_interlock
);

    // state machine
    parameter init = 0;
    parameter idle = 1;
    parameter dac_set = 2;
    parameter update = 3;
    parameter delay = 4;

    reg [2:0] state;
    reg [2:0] n_state;

    wire delay_flag;

    reg [4:0] dac_init_cnt;
    reg [4:0] delay_cnt;
    reg [1:0] dac_update_cnt;
    reg [DATA_WIDTH - 1 : 0] dac_old_data;

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
            init :
            begin
                if (dac_init_cnt == 30)
                    n_state <= idle;

                else
                    n_state <= init;
            end

            idle :
            begin
                if (dac_old_data != i_dac_data)
                    n_state <= dac_set;

                else
                    n_state <= idle;
            end

            dac_set :
            begin
                if (dac_old_data == i_dac_data)
                    n_state <= update;

                else
                    n_state <= dac_set;
            end

            update :
            begin
                if (i_spi_state == 4)               // spi 전송 완료
                    n_state <= delay;
                else
                    n_state <= update;
            end

            delay :
            begin
                if (delay_flag)              
                    n_state <= idle;
                else
                    n_state <= delay;
            end

            default :
                    n_state <= idle;
        endcase
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            dac_init_cnt <= 0;

        else if (state == init)
            dac_init_cnt <= dac_init_cnt + 1;

        else
            dac_init_cnt <= 0;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            dac_old_data <= 0;

        else if (state == dac_set)
            dac_old_data <= i_dac_data;

        else
            dac_old_data <= dac_old_data;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            o_spi_data <= 0;

        else if (state == update)
            o_spi_data <= dac_old_data;

        else
            o_spi_data <= 0;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            delay_cnt <= 0;

        else if ((state == delay) && (delay_cnt <= 30))
            delay_cnt <= delay_cnt + 1;

        else
            delay_cnt <= 0;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            dac_update_cnt <= 0;

        else if (state == update)
        begin
            if (dac_update_cnt < 3)
                dac_update_cnt <= dac_update_cnt + 1;

            else
                dac_update_cnt <= dac_update_cnt;
        end
        
        else
            dac_update_cnt <= 0;
    end

    assign o_spi_start = ((dac_update_cnt == 1) && ~i_interlock) ? 1 : 0;
    assign delay_flag = (delay_cnt == 30) ? 1 : 0;
    assign o_dac_trg_led_A = (i_interlock) ? 1 : 0;
    assign o_dac_trg_led_B = (i_interlock) ? 1 : 0;

endmodule