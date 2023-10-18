`timescale 1 ns / 1 ps
/*
입력 :  Pulse 수
        모터 속도
        방향
        Hold off
        Motor Start / Stop (ENMCKA - Interlock)

출력 :  현재 Pulse
        동작
*/
	module TOP_Motor #
	(
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,   // Register Data Width
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6     // Register Address Width
	)
	(
        // External Ports
        output o_motor_step,
        output o_motor_en,
        output o_motor_dir,
        output o_motor_hold_off,

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

    wire [31:0] step_read_cnt;
    wire motor_status;
    wire [31:0] step_set_cnt;
    wire [31:0] motor_speed;
    wire motor_run;

    S00_AXI # 
    (       
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) 
    u_S00_AXI 
    (
        .i_step_cnt(step_read_cnt),
        .i_motor_run(motor_status),

        .o_step_cnt(step_set_cnt),
        .o_motor_speed(motor_speed),
        .o_motor_run(motor_run),
        .o_dir(o_motor_dir),
        .o_hold_off(o_motor_hold_off),
        .o_motor_en(o_motor_en),

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

    Motor 
    u_Motor
    (
        .i_fRST(s00_axi_aresetn),
        .i_clk(s00_axi_aclk),

        // ZYNQ Ports
        .o_motor_step(o_motor_step),
        .i_step_cnt(step_set_cnt),
        .i_motor_speed(motor_speed),
        .i_motor_run(motor_run),
        .o_step_cnt(step_read_cnt),
        .o_motor_run(motor_status)
    );

endmodule