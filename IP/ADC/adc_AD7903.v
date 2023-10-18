`timescale 1ns / 1ps
/*
Conversion Time은 최소 130 * 5ns = 650ns는 설정해야 됨
SPI 통신이 최소 500ns임
ADC Freq = Min 1.2us
*/

module ADC_AD7903 #
(
    parameter integer DATA_WIDTH = 16,              // SPI Data 크기

    parameter integer AWIDTH = 16,
    parameter integer MEM_SIZE = 10000,

    parameter integer ADC_CONV_TIME = 130
)
(
    input i_fRST,
    input i_clk,

    // ZYNQ Ports
    input i_beam_trg,

    output o_adc_conv,
    output o_adc_trg,
    output o_beam_trg_led,
    output o_adc_trg_led,                               // 해당 핀으로 PS Interlock 사용. ram 저장 완료.

    // SPI
    input [2:0] i_spi_state,
    
    output o_spi_start,
    output [DATA_WIDTH - 1 : 0] o_spi_data,

    // ADC Setup
    input [9:0] i_adc_freq,                             // 240 (1.2us) ~ 1024 (5.12us)
    input [$clog2(MEM_SIZE) : 0] i_adc_data_ram_size,   // adc data ram 크기

    // RAM
    output reg [AWIDTH - 1 : 0] o_ram_addr,
    output o_ram_ce,                                    
    output o_ram_we
);

    // state machine
    parameter idle = 0;
    parameter adc_conv = 1;
    parameter adc_acq = 2;
    parameter save = 3;

    reg [2:0] state;
    reg [2:0] n_state;

    // time counter
    reg [9:0] adc_freq_cnt;         // i_adc_freq에 따름

    // flag
    wire adc_conv_flag;
    reg adc_done_flag;
    reg adc_trg_flag;


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
                if (adc_conv_flag)
                    n_state <= adc_conv;

                else
                    n_state <= idle;
            end

            adc_conv :
            begin
                if (o_spi_start)
                    n_state <= adc_acq;

                else
                    n_state <= adc_conv;
            end

            adc_acq :
            begin
                if (i_spi_state == 4)               // spi 전송 완료
                begin
                    if (adc_trg_flag)
                        n_state <= save;

                    else
                        n_state <= idle;
                end

                else
                    n_state <= adc_acq;
            end

            save :
            begin
                if (adc_done_flag)
                    n_state <= idle;

                else
                    n_state <= save;
            end

            default :
                    n_state <= idle;
        endcase
    end

    // adc 전체 동작 카운터
    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            adc_freq_cnt <= 0;

        else if (adc_freq_cnt == i_adc_freq)
            adc_freq_cnt <= 0;

        else
            adc_freq_cnt <= adc_freq_cnt + 1;
    end


    assign adc_conv_flag = ((adc_freq_cnt == 0) && (i_adc_freq != 0)) ? 1 : 0;          // ADC Conversion Start flag
    

    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            adc_done_flag <= 0;

        else if (state == save)
            adc_done_flag <= 1;

        else
            adc_done_flag <= 0;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            adc_trg_flag <= 0;

        else if (~i_beam_trg)
            adc_trg_flag <= 1;

        else if (o_ram_addr == i_adc_data_ram_size)
            adc_trg_flag <= 0;

        else
            adc_trg_flag <= adc_trg_flag;
    end


    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            o_ram_addr <= 0;

        else if (state == save)
            o_ram_addr <= o_ram_addr + 1;

        else if (!adc_trg_flag)
            o_ram_addr <= 0;

        else
            o_ram_addr <= o_ram_addr;
    end

    
    assign o_adc_conv = (adc_freq_cnt < ADC_CONV_TIME) ? 1 : 0;            // ADC Conversion Hold Time 700ns (500 ~ 710ns). 테스트 필요함
    assign o_spi_start = (adc_freq_cnt == (ADC_CONV_TIME + 1)) ? 1 : 0;                                  // ADC Acquisition Start flag (710ns)
    assign o_ram_we = 1;                                        // write only           
    assign o_ram_ce = 1;       
    assign o_spi_data = 0;                                      // mosi data는 사용하지 않음
    assign o_adc_trg_led = (state == idle) ? 1 : 0;
    assign o_beam_trg_led = ~adc_trg_flag;
    
endmodule
