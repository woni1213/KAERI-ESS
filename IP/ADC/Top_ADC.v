`timescale 1 ns / 1 ps
/*
System Clock : 200 MHz
따라서 1 Clock에 5ns임
*/

	module TOP_ADC #
	(
        parameter integer DATA_WIDTH = 16,
        parameter integer DELAY = 2,     
        parameter integer T_CYCLE = 2,                 // 반주기 = 10ns * T_CYCLE (50이면 1MHz (10ns * 50 * 2 = 1us))               

        parameter integer DWIDTH = 16,              // DPRAM Data
	    parameter integer AWIDTH = 16,              // DPRAM Memory Depth에 따라서 수정 필요
        parameter integer MEM_SIZE = 10000,         // DPRAM Memory Depth
        
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,   // Register Data Width
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6,     // Register Address Width

        parameter integer ADC_CONV_TIME = 130
	)
	(
        // External Ports
        input i_spi_adc_data,
        input i_beam_trg,

        output o_spi_adc_clk_1,
        output o_adc_conv,
        output o_adc_trg,
        output o_beam_trg_led,
        output o_adc_trg_led,

        output o_adc_flag,              // PS ADC Complete Flag

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

    // SPI
    wire [2:0] adc_spi_state;
    wire adc_spi_start;
    wire [DATA_WIDTH - 1 : 0] adc_spi_mosi_data;
    wire [DATA_WIDTH - 1 : 0] adc_spi_miso_data;

    // ADC Setup
    wire [9:0] adc_freq;
    wire [$clog2(MEM_SIZE) : 0] adc_data_ram_size;

    // RAM
    wire [AWIDTH - 1 : 0] ram_write_addr;
    wire ram_ce;
    wire ram_we;
    wire [AWIDTH - 1 : 0] ram_read_addr;

    wire [DWIDTH -1 : 0] mem_data;
    wire [DWIDTH -1 : 0] mem_data_dummy_1;
    wire [DWIDTH -1 : 0] mem_data_dummy_2;

    wire ce_en;
    wire we_read;

    S00_AXI # 
    (       
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SIZE(MEM_SIZE),
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),

		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) 
    u_S00_AXI 
    (
        .i_adc_spi_miso_data(adc_spi_miso_data),
        .i_adc_spi_state(adc_spi_state),

        .o_adc_freq(adc_freq),
        .o_adc_data_ram_size(adc_data_ram_size),

        .o_mem_addr(ram_read_addr),
        .i_mem_data(mem_data),

		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

    ADC_AD7903 #
    (
        .DATA_WIDTH(DATA_WIDTH),           

        .AWIDTH(AWIDTH),
        .MEM_SIZE(MEM_SIZE),

        .ADC_CONV_TIME(ADC_CONV_TIME)
    )
    u_ADC_AD7903
    (
        .i_fRST(s00_axi_aresetn),
        .i_clk(s00_axi_aclk),

        // ZYNQ Ports
        .i_beam_trg(i_beam_trg),

        .o_adc_conv(o_adc_conv),
        .o_adc_trg(o_adc_trg),
        .o_beam_trg_led(o_beam_trg_led),
        .o_adc_trg_led(o_adc_trg_led),

        // SPI
        .i_spi_state(adc_spi_state),
        
        .o_spi_start(adc_spi_start),
        .o_spi_data(adc_spi_mosi_data),

        // ADC Setup
        .i_adc_freq(adc_freq),                             // 100 (1us) ~ 1024 (10.24us)
        .i_adc_data_ram_size(adc_data_ram_size),   // adc data ram 크기

        // RAM
        .o_ram_addr(ram_write_addr),
        .o_ram_ce(ram_ce),                            
        .o_ram_we(ram_we)
    );

    SPI_AD7903 #
    (
        .DATA_WIDTH(DATA_WIDTH),  
        .T_CYCLE(T_CYCLE),                 // 반주기 = 10ns * T_CYCLE (50이면 1MHz (10ns * 50 * 2 = 1us))
        .DELAY(DELAY)                    // delay_1, delay_2 시간 (10ns * DELAY). 최소 5 이상 줘야함. (mosi data loading이 50ns에 발생)
    )
    u_SPI_AD7903
    (
        .i_fRST(s00_axi_aresetn),
        .i_clk(s00_axi_aclk),
        .i_spi_start(adc_spi_start),                              // spi 동작 신호. active H
        .i_mosi_data(adc_spi_mosi_data),           // MOSI Data
        .miso(i_spi_adc_data),                                     // 실제 miso 신호

        .o_miso_data(adc_spi_miso_data),          // MISO Data
        .spi_clk(o_spi_adc_clk_1),                                 // 실제 spi clock

        .o_spi_state(adc_spi_state)
    );

    DPBRAM #
    (
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),           // DPRAM Memory Depth에 따라서 수정 필요
        .MEM_SIZE(MEM_SIZE)
    )
    u_DPBRAM_A
    (
        .clk(s00_axi_aclk),
        .addr0(ram_write_addr),
        .ce0(ram_ce),
        .we0(ram_we),
        .din0(adc_spi_miso_data),
        .dout0(mem_data_dummy_1),
                    
        .addr1(ram_read_addr),
        .ce1(ce_en),
        .we1(we_read),
        .din1(mem_data_dummy_2),
        .dout1(mem_data)
    );

    assign ce_en = 1;
    assign we_read = 0;
    assign o_adc_flag = ~o_beam_trg_led;
endmodule
