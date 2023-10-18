`timescale 1 ns / 1 ps
/*
System Clock : 200 MHz
따라서 1 Clock에 5ns임
*/

	module Top_DAC_Test #
	(
        parameter integer DATA_WIDTH = 24,
        parameter integer DELAY = 4,     
        parameter integer T_CYCLE = 5,                 // 반주기 = 10ns * T_CYCLE (50이면 1MHz (10ns * 50 * 2 = 1us))               
        
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,   // Register Data Width
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6     // Register Address Width
	)
	(
        // External Ports
        output o_dac_res,
        output o_spi_dac_clk_1,                 // clk 그대로 쓰면 IP 만들때 크리티컬워닝 뜸
        output o_spi_dac_data,
        output o_dac_sync,
        output o_dac_trg_led_A,
        output o_dac_trg_led_B,


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
    wire [2:0] dac_spi_state;
    wire dac_spi_start;
    wire [DATA_WIDTH - 1 : 0] dac_spi_data;

    // AXI
    wire [DATA_WIDTH - 1:0] dac_data;
    wire interlock;

    S00_AXI # 
    (       
        .DATA_WIDTH(DATA_WIDTH),

		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) 
    u_S00_AXI 
    (
        .o_dac_data(dac_data),
        .o_interlock(interlock),

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

    DAC_DAC8563 #
    (
        .DATA_WIDTH(DATA_WIDTH)           
    )
    u_DAC_DAC8563
    (
        .i_fRST(s00_axi_aresetn),
        .i_clk(s00_axi_aclk),

        // ZYNQ Ports
        .o_dac_trg_led_A(o_dac_trg_led_A),
        .o_dac_trg_led_B(o_dac_trg_led_B),

        // SPI
        .i_spi_state(dac_spi_state),
        
        .o_spi_start(dac_spi_start),
        .o_spi_data(dac_spi_data),

        // AXI
        .i_dac_data(dac_data),
        .i_interlock(interlock)
    );

    SPI_DAC8563 #
    (
        .DATA_WIDTH(DATA_WIDTH),  
        .T_CYCLE(T_CYCLE),                 // 반주기 = 10ns * T_CYCLE (50이면 1MHz (10ns * 50 * 2 = 1us))
        .DELAY(DELAY)                    // delay_1, delay_2 시간 (10ns * DELAY). 최소 5 이상 줘야함. (mosi data loading이 50ns에 발생)
    )
    u_SPI_DAC8563
    (
        .i_fRST(s00_axi_aresetn),
        .i_clk(s00_axi_aclk),
        .i_spi_start(dac_spi_start),                              // spi 동작 신호. active H
        .i_mosi_data(dac_spi_data),           // MOSI Data
        //.miso(),                                     // 실제 miso 신호

        //.o_miso_data(),          // MISO Data
        .mosi(o_spi_dac_data),                                    // 실제 mosi 신호
        .cs(o_dac_sync),                                      // idle, done 빼고는 무조건 L임. active L
        .spi_clk(o_spi_dac_clk_1),                                 // 실제 spi clock

        .o_spi_state(dac_spi_state)
    );

    assign o_dac_res = ~interlock;

endmodule
