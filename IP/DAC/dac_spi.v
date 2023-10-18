`timescale 1ns / 1ps
/*

SPI Master Module
23.05.02

idle -> delay_1 -> run -> delay_2 -> done -> idle
 - 평상시에는 idle 상태
 - parameter 상수 값 변경해서 사용 (Data, T_CYCLE, Delay, CPOL, CPHA 등)
 - $clog2을 사용한 비트 범위 설정에서 -1을 하지않는 이유는 대부분 설정 값보다 + 1한 값까지 사용하기 때문임
 - i_mosi_data에 값을 쓴 후 i_spi_start를 H로 On.
 - SPI 통신 후에도 i_spi_start가 클리어되지 않으면 또 동작함. 그래서 바로 클리어 해줘야 좋음.
 - o_miso_data는 o_spi_state가 idle일때 Data Read해야함.

System Clock 5ns

*/


module SPI_DAC8563 #
(
    parameter integer DATA_WIDTH = 24,              // SPI Data 크기
    parameter integer T_CYCLE = 4,                 // 반주기 = 5ns * T_CYCLE
    parameter integer DELAY = 5                    // delay_1, delay_2 시간 (5ns * DELAY). 최소 2 이상 줘야함. (mosi data loading이 DELAY - 1에 발생)
)
(
    input i_fRST,
    input i_clk,
    input i_spi_start,                              // spi 동작 신호. active H
    input [DATA_WIDTH - 1:0] i_mosi_data,           // MOSI Data
    input miso,                                     // 실제 miso 신호

    output [DATA_WIDTH - 1:0] o_miso_data,          // MISO Data
    output mosi,                                    // 실제 mosi 신호
    output cs,                                      // idle, done 빼고는 무조건 L임. active L
    output spi_clk,                                 // 실제 spi clock

    output [2:0] o_spi_state
);

    parameter idle = 0;
    parameter delay_1 = 1;
    parameter run = 2;
    parameter delay_2 = 3;
    parameter done = 4;

    parameter CPOL = 1;                         // spi 설정
    parameter CPHA = 0;

    reg [2:0] state;
    reg [2:0] n_state;
    reg [$clog2(T_CYCLE) : 0] spi_clk_width_cnt;        // spi clock 시간 설정용 카운터. 해당 변수로 clock 주파수를 설정.

    reg [$clog2(DELAY) : 0] delay_1_cnt;
    reg [$clog2(DELAY) : 0] delay_2_cnt;
    reg [$clog2(DATA_WIDTH * 2) : 0] spi_clk_cnt;       // spi clock 카운터. 해당 변수로 데이터를 몇번 보냈는지 측정함. 반주기로 동작. (8 Bit면 총 16임)

    reg [DATA_WIDTH - 1 : 0] miso_reg;
    reg [DATA_WIDTH - 1 : 0] mosi_reg;

    // flag

    wire delay_1_flag;              
    wire delay_2_flag;
    reg spi_clk_flag;                   // spi clock의 H/L 용 flag
    wire spi_data_comp_flag;            // 모든 데이터 전송 완료

    wire spi_data_load_flag;            // mosi 데이터 로딩용 flag. delay_1이 5 카운트에 동작
    wire spi_data_p_flag;               // spi clock edge flag
    wire spi_data_n_flag;

    // state machine init.
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
                if (i_spi_start)
                    n_state <= delay_1;

                else
                    n_state <= idle;
            end

            delay_1 :
            begin
                if (delay_1_flag)
                    n_state <= run;

                else
                    n_state <= delay_1;
            end

            run :
            begin
                if (spi_data_comp_flag)
                    n_state <= delay_2;

                else
                    n_state <= run;
            end

            delay_2 :
            begin
                if (delay_2_flag)
                    n_state <= done;

                else
                    n_state <= delay_2;
            end

            done :
                n_state <= idle;


            default :
                    n_state <= idle;
        endcase
    end

    // delay_1 카운터
    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            delay_1_cnt <= 0;

        else if ((state == delay_1) && (delay_1_cnt <= DELAY))
            delay_1_cnt <= delay_1_cnt + 1;

        else
            delay_1_cnt <= 0;
    end

    // delay_2 카운터
    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            delay_2_cnt <= 0;

        else if ((state == delay_2) && (delay_2_cnt <= DELAY))
            delay_2_cnt <= delay_2_cnt + 1;

        else
            delay_2_cnt <= 0;
    end

    // spi clock 주파수 카운터
    // T_CYCLE까지 증가하면 0으로 초기화하고 다시 동작함
    // run state와 spi_clk_cnt가 설정값보다 낮을 경우 실행함
    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            spi_clk_width_cnt <= T_CYCLE + 1;

        else if ((state == run) && (spi_clk_cnt <= (DATA_WIDTH * 2)))
        begin
            if (spi_clk_width_cnt >= T_CYCLE)
                spi_clk_width_cnt <= 0;

            else
                spi_clk_width_cnt <= spi_clk_width_cnt + 1;  
        end

        else
            spi_clk_width_cnt <= T_CYCLE + 1;
    end

    // spi clock 카운터
    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            spi_clk_cnt <= 0;

        else if ((state == run) && (spi_clk_cnt <= (DATA_WIDTH * 2)))
        begin
            if (spi_clk_width_cnt == T_CYCLE)
                spi_clk_cnt <= spi_clk_cnt + 1;

            else
                spi_clk_cnt <= spi_clk_cnt;
        end

        else
            spi_clk_cnt <= 0;
    end

    // spi clock H/L 변경
    // 초기값은 CPOL에 따름
    always @(posedge i_clk or negedge i_fRST) 
    begin
        if (~i_fRST)
            spi_clk_flag <= CPOL;

        else if ((state == run) && (spi_clk_cnt <= (DATA_WIDTH * 2)))
        begin
            if (spi_clk_width_cnt == T_CYCLE)
            begin
                if (spi_clk_cnt == (DATA_WIDTH * 2))
                    spi_clk_flag <= spi_clk_flag;
                
                else
                    spi_clk_flag <= ~spi_clk_flag;
            end

            else
                spi_clk_flag <= spi_clk_flag;
        end

        else
            spi_clk_flag <= CPOL;
    end

    // miso
    always @(posedge i_clk or negedge i_fRST)
    begin
        if (~i_fRST)
            miso_reg <= 0;

        else
        begin
            if (spi_data_p_flag)
            begin
                if (CPOL^CPHA)
                    miso_reg <= miso_reg;

                else
                    miso_reg <= {miso_reg[DATA_WIDTH - 2:0], miso};
            end
            
            else if (spi_data_n_flag)
            begin
                if (CPOL^CPHA)
                    miso_reg <= {miso_reg[DATA_WIDTH - 2:0], miso};

                else
                    miso_reg <= miso_reg;
            end

            else
                miso_reg <= miso_reg;
        end
    end

    // mosi
    always @(posedge i_clk or negedge i_fRST)
    begin
        if (~i_fRST)
            mosi_reg <= 0;

        else
        begin
            if (spi_data_p_flag)
            begin
                if (CPOL^CPHA)
                begin
                    if (CPHA)
                    begin
                        if (spi_clk_cnt == 1)       // CPHA에 따라서 타이밍이 달라짐.
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end

                    else
                    begin
                        if (spi_clk_cnt == 0)
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end
                end

                else
                    mosi_reg <= mosi_reg;
            end
            
            else if (spi_data_n_flag)
            begin
                if (CPOL^CPHA)
                    mosi_reg <= mosi_reg;

                else
                begin
                    if (CPHA)
                    begin
                        if (spi_clk_cnt == 1)
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end

                    else
                    begin
                        if (spi_clk_cnt == 0)
                            mosi_reg <= mosi_reg;

                        else
                            mosi_reg <= {mosi_reg[DATA_WIDTH - 2:0], 1'b0};
                    end
                end  
            end

            else if (spi_data_load_flag)
                mosi_reg <= i_mosi_data;

            else
                mosi_reg <= mosi_reg;
        end
    end


    assign spi_clk = spi_clk_flag;
    assign spi_data_load_flag = (delay_1_cnt == (DELAY - 1)) ? 1 : 0;     // mosi data loading
    assign spi_data_p_flag = ((spi_clk_width_cnt == 0) && (spi_clk_flag) && (spi_clk_cnt <= (DATA_WIDTH * 2))) ? 1 : 0;         // 마지막 조건은 data 마지막에 한번 더 동작해서 조건을 걸었음
    assign spi_data_n_flag = ((spi_clk_width_cnt == 0) && (~spi_clk_flag) && (spi_clk_cnt <= (DATA_WIDTH * 2))) ? 1 : 0;
    assign delay_1_flag = (delay_1_cnt == DELAY) ? 1 : 0;
    assign delay_2_flag = (delay_2_cnt == DELAY) ? 1 : 0;
    assign spi_data_comp_flag = (spi_clk_cnt == ((DATA_WIDTH * 2) + 1)) ? 1 : 0;    // 맨 마지막 데이터를 처리한 후 동작함
    assign cs = ((state == idle) || (state == done)) ? 1 : 0;
    //assign o_miso_data = miso_reg;
    assign o_miso_data = (spi_data_comp_flag) ? miso_reg : o_miso_data;             // miso data는 전송이 완료된 후 write
    assign mosi = ( ~cs ) ? mosi_reg[DATA_WIDTH - 1] : 1'bz;

    assign o_spi_state = state;

endmodule
        
