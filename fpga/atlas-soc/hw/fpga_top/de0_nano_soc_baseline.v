//--------------------------------------------------------------------------//
// Title:        de0_nano_soc_baseline.v                                    //
// Rev:          Rev 0.1                                                    //
// Last Revised: 09/14/2015                                                 //
//--------------------------------------------------------------------------//
// Description: Baseline design file contains DE0 Nano SoC                  //
//              Board pins and I/O Standards.                               //
//--------------------------------------------------------------------------//
//Copyright 2015 Altera Corporation. All rights reserved.  Altera products
//are protected under numerous U.S. and foreign patents, maskwork rights,
//copyrights and other intellectual property laws.
//
//This reference design file, and your use thereof, is subject to and
//governed by the terms and conditions of the applicable Altera Reference
//Design License Agreement.  By using this reference design file, you
//indicate your acceptance of such terms and conditions between you and
//Altera Corporation.  In the event that you do not agree with such terms and
//conditions, you may not use the reference design file. Please promptly
//destroy any copies you have made.
//
//This reference design file being provided on an "as-is" basis and as an
//accommodation and therefore all warranties, representations or guarantees
//of any kind (whether express, implied or statutory) including, without
//limitation, warranties of merchantability, non-infringement, or fitness for
//a particular purpose, are specifically disclaimed.  By making this
//reference design file available, Altera expressly does not recommend,
//suggest or require that this reference design file be used in combination
//with any other product not provided by Altera
//----------------------------------------------------------------------------

//Group Enable Definitions
//This lists every pinout group
//Users can enable any group by uncommenting the corresponding line below:
//`define enable_ADC
//`define enable_ARDUINO
//`define enable_GPIO0
//`define enable_GPIO1
`define enable_HPS


module de0_nano_soc_baseline(

	//////////// CLOCK //////////
	input					CLOCK_50,
	input					CLOCK2_50,
	input					CLOCK3_50,

`ifdef enable_ADC
	//////////// ADC //////////
	/* 3.3-V LVTTL */
	output					ADC_CONVST,
	output					ADC_SCLK,
	output					ADC_SDI,
	input					ADC_SDO,
`endif

`ifdef enable_ARDUINO
	//////////// ARDUINO ////////////
	/* 3.3-V LVTTL */
	inout [15:0]				ARDUINO_IO,
	inout					ARDUINO_RESET_N,
`endif

`ifdef enable_GPIO0
	//////////// GPIO 0 ////////////
	/* 3.3-V LVTTL */
	inout [35:0]				GPIO_0,
`endif

`ifdef enable_GPIO1
	//////////// GPIO 1 ////////////
	/* 3.3-V LVTTL */
	inout [35:0]				GPIO_1,
`endif

`ifdef enable_HPS
	//////////// HPS //////////
	/* 3.3-V LVTTL */
	inout					HPS_CONV_USB_N,

	/* SSTL-15 Class I */
	output [14:0]				HPS_DDR3_ADDR,
	output [2:0]				HPS_DDR3_BA,
	output					HPS_DDR3_CAS_N,
	output					HPS_DDR3_CKE,
	output					HPS_DDR3_CS_N,
	output [3:0]				HPS_DDR3_DM,
	inout [31:0]				HPS_DDR3_DQ,
	output					HPS_DDR3_ODT,
	output					HPS_DDR3_RAS_N,
	output					HPS_DDR3_RESET_N,
	input 					HPS_DDR3_RZQ,
	output					HPS_DDR3_WE_N,
	/* DIFFERENTIAL 1.5-V SSTL CLASS I */
	output					HPS_DDR3_CK_N,
	output					HPS_DDR3_CK_P,
	inout [3:0]				HPS_DDR3_DQS_N,
	inout [3:0]				HPS_DDR3_DQS_P,

	/* 3.3-V LVTTL */
	output					HPS_ENET_GTX_CLK,
	inout					HPS_ENET_INT_N,
	output					HPS_ENET_MDC,
	inout					HPS_ENET_MDIO,
	input					HPS_ENET_RX_CLK,
	input [3:0]				HPS_ENET_RX_DATA,
	input					HPS_ENET_RX_DV,
	output [3:0]				HPS_ENET_TX_DATA,
	output					HPS_ENET_TX_EN,
	inout					HPS_GSENSOR_INT,
	inout					HPS_I2C0_SCLK,
	inout					HPS_I2C0_SDAT,
	inout					HPS_I2C1_SCLK,
	inout					HPS_I2C1_SDAT,
	inout					HPS_KEY,
	inout					HPS_LED,
	inout					HPS_LTC_GPIO,
	output					HPS_SD_CLK,
	inout					HPS_SD_CMD,
	inout [3:0]				HPS_SD_DATA,
	output					HPS_SPIM_CLK,
	input					HPS_SPIM_MISO,
	output					HPS_SPIM_MOSI,
	inout					HPS_SPIM_SS,
	input					HPS_UART_RX,
	output					HPS_UART_TX,
	input					HPS_USB_CLKOUT,
	inout [7:0]				HPS_USB_DATA,
	input					HPS_USB_DIR,
	input					HPS_USB_NXT,
	output					HPS_USB_STP,
`endif

	//////////// KEY ////////////
	/* 3.3-V LVTTL */
	input [1:0]				KEY,

	//////////// LED ////////////
	/* 3.3-V LVTTL */
	output [7:0]				LED,

	//////////// SW ////////////
	/* 3.3-V LVTTL */
	input [3:0]				SW
);


reg [7:0]	cntr;
reg		nrst_r;
wire		nrst = nrst_r & KEY[1];	/* KEY[1] is a reset button */


always @(posedge CLOCK_50)
begin
	if(cntr == 100)
	begin
		nrst_r <= 1'b1;
	end
	else
	begin
		nrst_r <= 1'b0;
		cntr <= cntr + 1'b1;
	end
end


wire [6:0]	axi_bridge_0_s0_awid;
wire [39:0]	axi_bridge_0_s0_awaddr;
wire [7:0]	axi_bridge_0_s0_awlen;
wire [2:0]	axi_bridge_0_s0_awsize;
wire [1:0]	axi_bridge_0_s0_awburst;
wire [0:0]	axi_bridge_0_s0_awlock;
wire [3:0]	axi_bridge_0_s0_awcache;
wire [2:0]	axi_bridge_0_s0_awprot;
wire		axi_bridge_0_s0_awvalid;
wire		axi_bridge_0_s0_awready;
wire [63:0]	axi_bridge_0_s0_wdata;
wire [7:0]	axi_bridge_0_s0_wstrb;
wire		axi_bridge_0_s0_wlast;
wire		axi_bridge_0_s0_wvalid;
wire		axi_bridge_0_s0_wready;
wire [6:0]	axi_bridge_0_s0_bid;
wire [1:0]	axi_bridge_0_s0_bresp;
wire		axi_bridge_0_s0_bvalid;
wire		axi_bridge_0_s0_bready;
wire [6:0]	axi_bridge_0_s0_arid;
wire [39:0]	axi_bridge_0_s0_araddr;
wire [7:0]	axi_bridge_0_s0_arlen;
wire [2:0]	axi_bridge_0_s0_arsize;
wire [1:0]	axi_bridge_0_s0_arburst;
wire [0:0]	axi_bridge_0_s0_arlock;
wire [3:0]	axi_bridge_0_s0_arcache;
wire [2:0]	axi_bridge_0_s0_arprot;
wire		axi_bridge_0_s0_arvalid;
wire		axi_bridge_0_s0_arready;
wire [6:0]	axi_bridge_0_s0_rid;
wire [63:0]	axi_bridge_0_s0_rdata;
wire [1:0]	axi_bridge_0_s0_rresp;
wire		axi_bridge_0_s0_rlast;
wire		axi_bridge_0_s0_rvalid;
wire		axi_bridge_0_s0_rready;

wire [6:0]	axi_bridge_1_s0_awid;
wire [39:0]	axi_bridge_1_s0_awaddr;
wire [7:0]	axi_bridge_1_s0_awlen;
wire [2:0]	axi_bridge_1_s0_awsize;
wire [1:0]	axi_bridge_1_s0_awburst;
wire [0:0]	axi_bridge_1_s0_awlock;
wire [3:0]	axi_bridge_1_s0_awcache;
wire [2:0]	axi_bridge_1_s0_awprot;
wire		axi_bridge_1_s0_awvalid;
wire		axi_bridge_1_s0_awready;
wire [63:0]	axi_bridge_1_s0_wdata;
wire [7:0]	axi_bridge_1_s0_wstrb;
wire		axi_bridge_1_s0_wlast;
wire		axi_bridge_1_s0_wvalid;
wire		axi_bridge_1_s0_wready;
wire [6:0]	axi_bridge_1_s0_bid;
wire [1:0]	axi_bridge_1_s0_bresp;
wire		axi_bridge_1_s0_bvalid;
wire		axi_bridge_1_s0_bready;
wire [6:0]	axi_bridge_1_s0_arid;
wire [39:0]	axi_bridge_1_s0_araddr;
wire [7:0]	axi_bridge_1_s0_arlen;
wire [2:0]	axi_bridge_1_s0_arsize;
wire [1:0]	axi_bridge_1_s0_arburst;
wire [0:0]	axi_bridge_1_s0_arlock;
wire [3:0]	axi_bridge_1_s0_arcache;
wire [2:0]	axi_bridge_1_s0_arprot;
wire		axi_bridge_1_s0_arvalid;
wire		axi_bridge_1_s0_arready;
wire [6:0]	axi_bridge_1_s0_rid;
wire [63:0]	axi_bridge_1_s0_rdata;
wire [1:0]	axi_bridge_1_s0_rresp;
wire		axi_bridge_1_s0_rlast;
wire		axi_bridge_1_s0_rvalid;
wire		axi_bridge_1_s0_rready;

wire [31:0]	hps_0_f2h_irq1_irq;

wire [6:0]	axi_bridge_2_m0_awid;
wire [11:0]	axi_bridge_2_m0_awaddr;
wire [7:0]	axi_bridge_2_m0_awlen;
wire [2:0]	axi_bridge_2_m0_awsize;
wire [1:0]	axi_bridge_2_m0_awburst;
wire [0:0]	axi_bridge_2_m0_awlock;
wire [3:0]	axi_bridge_2_m0_awcache;
wire [2:0]	axi_bridge_2_m0_awprot;
wire		axi_bridge_2_m0_awvalid;
wire		axi_bridge_2_m0_awready;
wire [31:0]	axi_bridge_2_m0_wdata;
wire [3:0]	axi_bridge_2_m0_wstrb;
wire		axi_bridge_2_m0_wlast;
wire		axi_bridge_2_m0_wvalid;
wire		axi_bridge_2_m0_wready;
wire [6:0]	axi_bridge_2_m0_bid;
wire [1:0]	axi_bridge_2_m0_bresp;
wire		axi_bridge_2_m0_bvalid;
wire		axi_bridge_2_m0_bready;
wire [6:0]	axi_bridge_2_m0_arid;
wire [11:0]	axi_bridge_2_m0_araddr;
wire [7:0]	axi_bridge_2_m0_arlen;
wire [2:0]	axi_bridge_2_m0_arsize;
wire [1:0]	axi_bridge_2_m0_arburst;
wire [0:0]	axi_bridge_2_m0_arlock;
wire [3:0]	axi_bridge_2_m0_arcache;
wire [2:0]	axi_bridge_2_m0_arprot;
wire		axi_bridge_2_m0_arvalid;
wire		axi_bridge_2_m0_arready;
wire [6:0]	axi_bridge_2_m0_rid;
wire [31:0]	axi_bridge_2_m0_rdata;
wire [1:0]	axi_bridge_2_m0_rresp;
wire		axi_bridge_2_m0_rlast;
wire		axi_bridge_2_m0_rvalid;
wire		axi_bridge_2_m0_rready;


wire vxe_intr;

assign hps_0_f2h_irq1_irq = { 31'h0, vxe_intr };


hps u0 (
	.axi_bridge_0_s0_awid    (axi_bridge_0_s0_awid),
	.axi_bridge_0_s0_awaddr  (axi_bridge_0_s0_awaddr),
	.axi_bridge_0_s0_awlen   (axi_bridge_0_s0_awlen),
	.axi_bridge_0_s0_awsize  (axi_bridge_0_s0_awsize),
	.axi_bridge_0_s0_awburst (axi_bridge_0_s0_awburst),
	.axi_bridge_0_s0_awlock  (axi_bridge_0_s0_awlock),
	.axi_bridge_0_s0_awcache (axi_bridge_0_s0_awcache),
	.axi_bridge_0_s0_awprot  (axi_bridge_0_s0_awprot),
	.axi_bridge_0_s0_awvalid (axi_bridge_0_s0_awvalid),
	.axi_bridge_0_s0_awready (axi_bridge_0_s0_awready),
	.axi_bridge_0_s0_wdata   (axi_bridge_0_s0_wdata),
	.axi_bridge_0_s0_wstrb   (axi_bridge_0_s0_wstrb),
	.axi_bridge_0_s0_wlast   (axi_bridge_0_s0_wlast),
	.axi_bridge_0_s0_wvalid  (axi_bridge_0_s0_wvalid),
	.axi_bridge_0_s0_wready  (axi_bridge_0_s0_wready),
	.axi_bridge_0_s0_bid     (axi_bridge_0_s0_bid),
	.axi_bridge_0_s0_bresp   (axi_bridge_0_s0_bresp),
	.axi_bridge_0_s0_bvalid  (axi_bridge_0_s0_bvalid),
	.axi_bridge_0_s0_bready  (axi_bridge_0_s0_bready),
	.axi_bridge_0_s0_arid    (axi_bridge_0_s0_arid),
	.axi_bridge_0_s0_araddr  (axi_bridge_0_s0_araddr),
	.axi_bridge_0_s0_arlen   (axi_bridge_0_s0_arlen),
	.axi_bridge_0_s0_arsize  (axi_bridge_0_s0_arsize),
	.axi_bridge_0_s0_arburst (axi_bridge_0_s0_arburst),
	.axi_bridge_0_s0_arlock  (axi_bridge_0_s0_arlock),
	.axi_bridge_0_s0_arcache (axi_bridge_0_s0_arcache),
	.axi_bridge_0_s0_arprot  (axi_bridge_0_s0_arprot),
	.axi_bridge_0_s0_arvalid (axi_bridge_0_s0_arvalid),
	.axi_bridge_0_s0_arready (axi_bridge_0_s0_arready),
	.axi_bridge_0_s0_rid     (axi_bridge_0_s0_rid),
	.axi_bridge_0_s0_rdata   (axi_bridge_0_s0_rdata),
	.axi_bridge_0_s0_rresp   (axi_bridge_0_s0_rresp),
	.axi_bridge_0_s0_rlast   (axi_bridge_0_s0_rlast),
	.axi_bridge_0_s0_rvalid  (axi_bridge_0_s0_rvalid),
	.axi_bridge_0_s0_rready  (axi_bridge_0_s0_rready),
	.axi_bridge_1_s0_awid    (axi_bridge_1_s0_awid),
	.axi_bridge_1_s0_awaddr  (axi_bridge_1_s0_awaddr),
	.axi_bridge_1_s0_awlen   (axi_bridge_1_s0_awlen),
	.axi_bridge_1_s0_awsize  (axi_bridge_1_s0_awsize),
	.axi_bridge_1_s0_awburst (axi_bridge_1_s0_awburst),
	.axi_bridge_1_s0_awlock  (axi_bridge_1_s0_awlock),
	.axi_bridge_1_s0_awcache (axi_bridge_1_s0_awcache),
	.axi_bridge_1_s0_awprot  (axi_bridge_1_s0_awprot),
	.axi_bridge_1_s0_awvalid (axi_bridge_1_s0_awvalid),
	.axi_bridge_1_s0_awready (axi_bridge_1_s0_awready),
	.axi_bridge_1_s0_wdata   (axi_bridge_1_s0_wdata),
	.axi_bridge_1_s0_wstrb   (axi_bridge_1_s0_wstrb),
	.axi_bridge_1_s0_wlast   (axi_bridge_1_s0_wlast),
	.axi_bridge_1_s0_wvalid  (axi_bridge_1_s0_wvalid),
	.axi_bridge_1_s0_wready  (axi_bridge_1_s0_wready),
	.axi_bridge_1_s0_bid     (axi_bridge_1_s0_bid),
	.axi_bridge_1_s0_bresp   (axi_bridge_1_s0_bresp),
	.axi_bridge_1_s0_bvalid  (axi_bridge_1_s0_bvalid),
	.axi_bridge_1_s0_bready  (axi_bridge_1_s0_bready),
	.axi_bridge_1_s0_arid    (axi_bridge_1_s0_arid),
	.axi_bridge_1_s0_araddr  (axi_bridge_1_s0_araddr),
	.axi_bridge_1_s0_arlen   (axi_bridge_1_s0_arlen),
	.axi_bridge_1_s0_arsize  (axi_bridge_1_s0_arsize),
	.axi_bridge_1_s0_arburst (axi_bridge_1_s0_arburst),
	.axi_bridge_1_s0_arlock  (axi_bridge_1_s0_arlock),
	.axi_bridge_1_s0_arcache (axi_bridge_1_s0_arcache),
	.axi_bridge_1_s0_arprot  (axi_bridge_1_s0_arprot),
	.axi_bridge_1_s0_arvalid (axi_bridge_1_s0_arvalid),
	.axi_bridge_1_s0_arready (axi_bridge_1_s0_arready),
	.axi_bridge_1_s0_rid     (axi_bridge_1_s0_rid),
	.axi_bridge_1_s0_rdata   (axi_bridge_1_s0_rdata),
	.axi_bridge_1_s0_rresp   (axi_bridge_1_s0_rresp),
	.axi_bridge_1_s0_rlast   (axi_bridge_1_s0_rlast),
	.axi_bridge_1_s0_rvalid  (axi_bridge_1_s0_rvalid),
	.axi_bridge_1_s0_rready  (axi_bridge_1_s0_rready),
	.clk_clk                 (CLOCK_50),
	.hps_0_f2h_irq1_irq      (hps_0_f2h_irq1_irq),
	.memory_mem_a            (HPS_DDR3_ADDR),
	.memory_mem_ba           (HPS_DDR3_BA),
	.memory_mem_ck           (HPS_DDR3_CK_P),
	.memory_mem_ck_n         (HPS_DDR3_CK_N),
	.memory_mem_cke          (HPS_DDR3_CKE),
	.memory_mem_cs_n         (HPS_DDR3_CS_N),
	.memory_mem_ras_n        (HPS_DDR3_RAS_N),
	.memory_mem_cas_n        (HPS_DDR3_CAS_N),
	.memory_mem_we_n         (HPS_DDR3_WE_N),
	.memory_mem_reset_n      (HPS_DDR3_RESET_N),
	.memory_mem_dq           (HPS_DDR3_DQ),
	.memory_mem_dqs          (HPS_DDR3_DQS_P),
	.memory_mem_dqs_n        (HPS_DDR3_DQS_N),
	.memory_mem_odt          (HPS_DDR3_ODT),
	.memory_mem_dm           (HPS_DDR3_DM),
	.memory_oct_rzqin        (HPS_DDR3_RZQ),
	.axi_bridge_2_m0_awid    (axi_bridge_2_m0_awid),
	.axi_bridge_2_m0_awaddr  (axi_bridge_2_m0_awaddr),
	.axi_bridge_2_m0_awlen   (axi_bridge_2_m0_awlen),
	.axi_bridge_2_m0_awsize  (axi_bridge_2_m0_awsize),
	.axi_bridge_2_m0_awburst (axi_bridge_2_m0_awburst),
	.axi_bridge_2_m0_awlock  (axi_bridge_2_m0_awlock),
	.axi_bridge_2_m0_awcache (axi_bridge_2_m0_awcache),
	.axi_bridge_2_m0_awprot  (axi_bridge_2_m0_awprot),
	.axi_bridge_2_m0_awvalid (axi_bridge_2_m0_awvalid),
	.axi_bridge_2_m0_awready (axi_bridge_2_m0_awready),
	.axi_bridge_2_m0_wdata   (axi_bridge_2_m0_wdata),
	.axi_bridge_2_m0_wstrb   (axi_bridge_2_m0_wstrb),
	.axi_bridge_2_m0_wlast   (axi_bridge_2_m0_wlast),
	.axi_bridge_2_m0_wvalid  (axi_bridge_2_m0_wvalid),
	.axi_bridge_2_m0_wready  (axi_bridge_2_m0_wready),
	.axi_bridge_2_m0_bid     (axi_bridge_2_m0_bid),
	.axi_bridge_2_m0_bresp   (axi_bridge_2_m0_bresp),
	.axi_bridge_2_m0_bvalid  (axi_bridge_2_m0_bvalid),
	.axi_bridge_2_m0_bready  (axi_bridge_2_m0_bready),
	.axi_bridge_2_m0_arid    (axi_bridge_2_m0_arid),
	.axi_bridge_2_m0_araddr  (axi_bridge_2_m0_araddr),
	.axi_bridge_2_m0_arlen   (axi_bridge_2_m0_arlen),
	.axi_bridge_2_m0_arsize  (axi_bridge_2_m0_arsize),
	.axi_bridge_2_m0_arburst (axi_bridge_2_m0_arburst),
	.axi_bridge_2_m0_arlock  (axi_bridge_2_m0_arlock),
	.axi_bridge_2_m0_arcache (axi_bridge_2_m0_arcache),
	.axi_bridge_2_m0_arprot  (axi_bridge_2_m0_arprot),
	.axi_bridge_2_m0_arvalid (axi_bridge_2_m0_arvalid),
	.axi_bridge_2_m0_arready (axi_bridge_2_m0_arready),
	.axi_bridge_2_m0_rid     (axi_bridge_2_m0_rid),
	.axi_bridge_2_m0_rdata   (axi_bridge_2_m0_rdata),
	.axi_bridge_2_m0_rresp   (axi_bridge_2_m0_rresp),
	.axi_bridge_2_m0_rlast   (axi_bridge_2_m0_rlast),
	.axi_bridge_2_m0_rvalid  (axi_bridge_2_m0_rvalid),
	.axi_bridge_2_m0_rready  (axi_bridge_2_m0_rready),
);


vxe_top #(
	.MEMIF_FIFO_DEPTH_POW2(1),		/* Memory IF FIFOs depth */
	.SINGLE_VPU_CONFIG(1),			/* Instantiate only one VPU */
	.CU_CMD_FETCH_DEPTH_POW2(2),		/* Command fetch FIFO depth */
	.CU_VPU_FWD_DEPTH_POW2(2),		/* VPU forwarding FIFO depth */
	.VPU_CMD_DEPTH_POW2(1),			/* Command FIFO depth */
	.VPU_LSU_NR_REQ_POW2(2),		/* No. Requests on the fly */
	.VPU_LSU_RD_DEPTH_POW2(1),		/* Read requests FIFO depth */
	.VPU_LSU_WR_DEPTH_POW2(1),		/* Write requests FIFO depth */
	.VPU_LSU_RS_DEPTH_POW2(1),		/* Read responses FIFO depth */
	.VPU_PROD_EU_WE_DEPTH_POW2(2),		/* Write enable FIFOs depth */
	.VPU_PROD_EU_OP_DEPTH_POW2(2),		/* Operand FIFOs depth */
	.VPU_PROD_EU_RQD_IN_DEPTH_POW2(1),	/* Incoming request FIFOs depth */
	.VPU_PROD_EU_RQD_OUT_DEPTH_POW2(1),	/* Outgoing request FIFOs depth */
	.VPU_PROD_EU_RSD_IN_WE_DEPTH_POW2(1),	/* Incoming write enable FIFOs depth */
	.VPU_PROD_EU_RSD_IN_RS_DEPTH_POW2(1),	/* Incoming response FIFO depth */
	.VPU_PROD_EU_RSD_OUT_OP_DEPTH_POW2(1),	/* Outgoing operand FIFOs depth */
	.VPU_PROD_EU_FMAC_IN_OP_DEPTH_POW2(1)	/* Incoming operand FIFOs depth */
) vxe (
	.clk(CLOCK_50),
	.nrst(nrst),
	/* Interrupt output */
	.o_intr(vxe_intr),
	/* AXI4 Slave */
	.S0_AXI4_AWID(axi_bridge_2_m0_awid),
	.S0_AXI4_AWADDR(axi_bridge_2_m0_awaddr),
	.S0_AXI4_AWLEN(axi_bridge_2_m0_awlen),
	.S0_AXI4_AWSIZE(axi_bridge_2_m0_awsize),
	.S0_AXI4_AWBURST(axi_bridge_2_m0_awburst),
	.S0_AXI4_AWLOCK(axi_bridge_2_m0_awlock),
	.S0_AXI4_AWCACHE(axi_bridge_2_m0_awcache),
	.S0_AXI4_AWPROT(axi_bridge_2_m0_awprot),
	.S0_AXI4_AWVALID(axi_bridge_2_m0_awvalid),
	.S0_AXI4_AWREADY(axi_bridge_2_m0_awready),
	.S0_AXI4_WDATA(axi_bridge_2_m0_wdata),
	.S0_AXI4_WSTRB(axi_bridge_2_m0_wstrb),
	.S0_AXI4_WLAST(axi_bridge_2_m0_wlast),
	.S0_AXI4_WVALID(axi_bridge_2_m0_wvalid),
	.S0_AXI4_WREADY(axi_bridge_2_m0_wready),
	.S0_AXI4_BID(axi_bridge_2_m0_bid),
	.S0_AXI4_BRESP(axi_bridge_2_m0_bresp),
	.S0_AXI4_BVALID(axi_bridge_2_m0_bvalid),
	.S0_AXI4_BREADY(axi_bridge_2_m0_bready),
	.S0_AXI4_ARID(axi_bridge_2_m0_arid),
	.S0_AXI4_ARADDR(axi_bridge_2_m0_araddr),
	.S0_AXI4_ARLEN(axi_bridge_2_m0_arlen),
	.S0_AXI4_ARSIZE(axi_bridge_2_m0_arsize),
	.S0_AXI4_ARBURST(axi_bridge_2_m0_arburst),
	.S0_AXI4_ARLOCK(axi_bridge_2_m0_arlock),
	.S0_AXI4_ARCACHE(axi_bridge_2_m0_arcache),
	.S0_AXI4_ARPROT(axi_bridge_2_m0_arprot),
	.S0_AXI4_ARVALID(axi_bridge_2_m0_arvalid),
	.S0_AXI4_ARREADY(axi_bridge_2_m0_arready),
	.S0_AXI4_RID(axi_bridge_2_m0_rid),
	.S0_AXI4_RDATA(axi_bridge_2_m0_rdata),
	.S0_AXI4_RRESP(axi_bridge_2_m0_rresp),
	.S0_AXI4_RLAST(axi_bridge_2_m0_rlast),
	.S0_AXI4_RVALID(axi_bridge_2_m0_rvalid),
	.S0_AXI4_RREADY(axi_bridge_2_m0_rready),
	/* AXI4 Master 0 */
	.M0_AXI4_AWID(axi_bridge_0_s0_awid),
	.M0_AXI4_AWADDR(axi_bridge_0_s0_awaddr),
	.M0_AXI4_AWLEN(axi_bridge_0_s0_awlen),
	.M0_AXI4_AWSIZE(axi_bridge_0_s0_awsize),
	.M0_AXI4_AWBURST(axi_bridge_0_s0_awburst),
	.M0_AXI4_AWLOCK(axi_bridge_0_s0_awlock),
	.M0_AXI4_AWCACHE(axi_bridge_0_s0_awcache),
	.M0_AXI4_AWPROT(axi_bridge_0_s0_awprot),
	.M0_AXI4_AWVALID(axi_bridge_0_s0_awvalid),
	.M0_AXI4_AWREADY(axi_bridge_0_s0_awready),
	.M0_AXI4_WDATA(axi_bridge_0_s0_wdata),
	.M0_AXI4_WSTRB(axi_bridge_0_s0_wstrb),
	.M0_AXI4_WLAST(axi_bridge_0_s0_wlast),
	.M0_AXI4_WVALID(axi_bridge_0_s0_wvalid),
	.M0_AXI4_WREADY(axi_bridge_0_s0_wready),
	.M0_AXI4_BID(axi_bridge_0_s0_bid),
	.M0_AXI4_BRESP(axi_bridge_0_s0_bresp),
	.M0_AXI4_BVALID(axi_bridge_0_s0_bvalid),
	.M0_AXI4_BREADY(axi_bridge_0_s0_bready),
	.M0_AXI4_ARID(axi_bridge_0_s0_arid),
	.M0_AXI4_ARADDR(axi_bridge_0_s0_araddr),
	.M0_AXI4_ARLEN(axi_bridge_0_s0_arlen),
	.M0_AXI4_ARSIZE(axi_bridge_0_s0_arsize),
	.M0_AXI4_ARBURST(axi_bridge_0_s0_arburst),
	.M0_AXI4_ARLOCK(axi_bridge_0_s0_arlock),
	.M0_AXI4_ARCACHE(axi_bridge_0_s0_arcache),
	.M0_AXI4_ARPROT(axi_bridge_0_s0_arprot),
	.M0_AXI4_ARVALID(axi_bridge_0_s0_arvalid),
	.M0_AXI4_ARREADY(axi_bridge_0_s0_arready),
	.M0_AXI4_RID(axi_bridge_0_s0_rid),
	.M0_AXI4_RDATA(axi_bridge_0_s0_rdata),
	.M0_AXI4_RRESP(axi_bridge_0_s0_rresp),
	.M0_AXI4_RLAST(axi_bridge_0_s0_rlast),
	.M0_AXI4_RVALID(axi_bridge_0_s0_rvalid),
	.M0_AXI4_RREADY(axi_bridge_0_s0_rready),
	/* AXI4 Master 1 */
	.M1_AXI4_AWID(axi_bridge_1_s0_awid),
	.M1_AXI4_AWADDR(axi_bridge_1_s0_awaddr),
	.M1_AXI4_AWLEN(axi_bridge_1_s0_awlen),
	.M1_AXI4_AWSIZE(axi_bridge_1_s0_awsize),
	.M1_AXI4_AWBURST(axi_bridge_1_s0_awburst),
	.M1_AXI4_AWLOCK(axi_bridge_1_s0_awlock),
	.M1_AXI4_AWCACHE(axi_bridge_1_s0_awcache),
	.M1_AXI4_AWPROT(axi_bridge_1_s0_awprot),
	.M1_AXI4_AWVALID(axi_bridge_1_s0_awvalid),
	.M1_AXI4_AWREADY(axi_bridge_1_s0_awready),
	.M1_AXI4_WDATA(axi_bridge_1_s0_wdata),
	.M1_AXI4_WSTRB(axi_bridge_1_s0_wstrb),
	.M1_AXI4_WLAST(axi_bridge_1_s0_wlast),
	.M1_AXI4_WVALID(axi_bridge_1_s0_wvalid),
	.M1_AXI4_WREADY(axi_bridge_1_s0_wready),
	.M1_AXI4_BID(axi_bridge_1_s0_bid),
	.M1_AXI4_BRESP(axi_bridge_1_s0_bresp),
	.M1_AXI4_BVALID(axi_bridge_1_s0_bvalid),
	.M1_AXI4_BREADY(axi_bridge_1_s0_bready),
	.M1_AXI4_ARID(axi_bridge_1_s0_arid),
	.M1_AXI4_ARADDR(axi_bridge_1_s0_araddr),
	.M1_AXI4_ARLEN(axi_bridge_1_s0_arlen),
	.M1_AXI4_ARSIZE(axi_bridge_1_s0_arsize),
	.M1_AXI4_ARBURST(axi_bridge_1_s0_arburst),
	.M1_AXI4_ARLOCK(axi_bridge_1_s0_arlock),
	.M1_AXI4_ARCACHE(axi_bridge_1_s0_arcache),
	.M1_AXI4_ARPROT(axi_bridge_1_s0_arprot),
	.M1_AXI4_ARVALID(axi_bridge_1_s0_arvalid),
	.M1_AXI4_ARREADY(axi_bridge_1_s0_arready),
	.M1_AXI4_RID(axi_bridge_1_s0_rid),
	.M1_AXI4_RDATA(axi_bridge_1_s0_rdata),
	.M1_AXI4_RRESP(axi_bridge_1_s0_rresp),
	.M1_AXI4_RLAST(axi_bridge_1_s0_rlast),
	.M1_AXI4_RVALID(axi_bridge_1_s0_rvalid),
	.M1_AXI4_RREADY(axi_bridge_1_s0_rready)
);


endmodule
