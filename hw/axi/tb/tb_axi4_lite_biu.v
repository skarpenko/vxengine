/*
 * Copyright (c) 2020 The VxEngine Project. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * Testbench for AXI4-Lite bus interface unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_axi4_lite_biu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam ADDR_WIDTH = 32;
	localparam DATA_WIDTH = 32;

	reg			clk;
	reg			nrst;
	/* AXI write address channel */
	reg [ADDR_WIDTH-1:0]	S_AXI_AWADDR;
	reg [2:0]		S_AXI_AWPROT;
	reg			S_AXI_AWVALID;
	wire			S_AXI_AWREADY;
	/* AXI write data channel */
	reg [DATA_WIDTH-1:0]	S_AXI_WDATA;
	reg [DATA_WIDTH/8-1:0]	S_AXI_WSTRB;
	reg			S_AXI_WVALID;
	wire			S_AXI_WREADY;
	/* AXI write response channel */
	wire [1:0]		S_AXI_BRESP;
	wire			S_AXI_BVALID;
	reg			S_AXI_BREADY;
	/* AXI read address channel */
	reg [ADDR_WIDTH-1:0]	S_AXI_ARADDR;
	reg [2:0]		S_AXI_ARPROT;
	reg			S_AXI_ARVALID;
	wire			S_AXI_ARREADY;
	/* AXI read data channel */
	wire [DATA_WIDTH-1:0]	S_AXI_RDATA;
	wire [1:0]		S_AXI_RRESP;
	wire			S_AXI_RVALID;
	reg			S_AXI_RREADY;
	/* BIU interface write path */
	wire [ADDR_WIDTH-1:0]	biu_waddr;
	wire			biu_wenable;
	wire [DATA_WIDTH-1:0]	biu_wdata;
	wire [DATA_WIDTH/8-1:0]	biu_wben;
	reg			biu_waccept;
	reg			biu_werror;
	/* BIU interface read path */
	wire [ADDR_WIDTH-1:0]	biu_raddr;
	wire			biu_renable;
	reg [DATA_WIDTH-1:0]	biu_rdata;
	reg			biu_raccept;
	reg			biu_rerror;


	always
		#HCLK clk = !clk;


	/* AXI4-Lite read */
	task axi_read;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data;
	input rready;
	input raccept;
	begin
		@(posedge clk)
		begin
			S_AXI_ARADDR <= addr;
			S_AXI_ARVALID <= 1'b1;
			S_AXI_RREADY <= rready;
			biu_raccept <= raccept;
			biu_rdata <= data;
		end

		@(posedge clk)
		begin
			S_AXI_ARVALID <= 1'b0;
		end

		@(posedge clk)
		begin
		end
	end
	endtask


	/* AXI4-Lite write */
	task axi_write;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data;
	input bready;
	input waccept;
	begin
		@(posedge clk)
		begin
			S_AXI_AWADDR <= addr;
			S_AXI_AWPROT <= 3'b0;
			S_AXI_AWVALID <= 1'b1;
			S_AXI_WDATA <= data;
			S_AXI_WSTRB <= 4'hf;
			S_AXI_WVALID <= 1'b1;
			S_AXI_BREADY <= bready;
			biu_waccept <= waccept;
		end

		@(posedge clk)
		begin
			S_AXI_AWVALID <= 1'b0;
			S_AXI_WVALID <= 1'b0;
		end

		@(posedge clk)
		begin
		end
	end
	endtask


	task wait_pos_clk;
		@(posedge clk);
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_axi4_lite_biu);

		clk = 1;
		nrst = 0;

		S_AXI_AWADDR = {ADDR_WIDTH{1'b0}};
		S_AXI_AWPROT = 3'b0;
		S_AXI_AWVALID = 1'b0;
		S_AXI_WDATA = {DATA_WIDTH{1'b0}};
		S_AXI_WSTRB = {DATA_WIDTH/8{1'b0}};
		S_AXI_WVALID = 1'b0;
		S_AXI_BREADY = 2'b0;
		S_AXI_ARADDR = {ADDR_WIDTH{1'b0}};
		S_AXI_ARPROT = 3'b0;
		S_AXI_ARVALID = 1'b0;
		S_AXI_RREADY = 1'b0;
		biu_waccept = 1'b0;
		biu_werror = 1'b0;
		biu_rdata = {DATA_WIDTH{1'b0}};
		biu_raccept = 1'b0;
		biu_rerror = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();

		axi_read(32'h0000_000c, 32'hfefe_fafa, 1'b1, 1'b1);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		axi_read(32'h0000_000c, 32'hfefe_fafa, 1'b0, 1'b1);

		wait_pos_clk();

		@(posedge clk)
		begin
			S_AXI_RREADY <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		axi_read(32'h0000_000c, 32'hfefe_fafa, 1'b1, 1'b0);

		wait_pos_clk();

		@(posedge clk)
		begin
			biu_raccept <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		axi_write(32'h0000_000c, 32'hf1f2_f3f4, 1'b1, 1'b1);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		axi_write(32'h0000_000c, 32'hf1f2_f3f4, 1'b0, 1'b1);

		wait_pos_clk();

		@(posedge clk)
		begin
			S_AXI_BREADY <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		axi_write(32'h0000_000c, 32'hf1f2_f3f4, 1'b1, 1'b0);

		wait_pos_clk();

		@(posedge clk)
		begin
			biu_waccept <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		#500 $finish;
	end


	/* AXI4-Lite BIU instance */
	axi4_lite_biu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) biu (
		.S_AXI_ACLK(clk),
		.S_AXI_ARESETn(nrst),
		/* AXI channels */
		.S_AXI_AWADDR(S_AXI_AWADDR),
		.S_AXI_AWPROT(S_AXI_AWPROT),
		.S_AXI_AWVALID(S_AXI_AWVALID),
		.S_AXI_AWREADY(S_AXI_AWREADY),
		.S_AXI_WDATA(S_AXI_WDATA),
		.S_AXI_WSTRB(S_AXI_WSTRB),
		.S_AXI_WVALID(S_AXI_WVALID),
		.S_AXI_WREADY(S_AXI_WREADY),
		.S_AXI_BRESP(S_AXI_BRESP),
		.S_AXI_BVALID(S_AXI_BVALID),
		.S_AXI_BREADY(S_AXI_BREADY),
		.S_AXI_ARADDR(S_AXI_ARADDR),
		.S_AXI_ARPROT(S_AXI_ARPROT),
		.S_AXI_ARVALID(S_AXI_ARVALID),
		.S_AXI_ARREADY(S_AXI_ARREADY),
		.S_AXI_RDATA(S_AXI_RDATA),
		.S_AXI_RRESP(S_AXI_RRESP),
		.S_AXI_RVALID(S_AXI_RVALID),
		.S_AXI_RREADY(S_AXI_RREADY),
		/* BIU interface */
		.biu_waddr(biu_waddr),
		.biu_wenable(biu_wenable),
		.biu_wdata(biu_wdata),
		.biu_wben(biu_wben),
		.biu_waccept(biu_waccept),
		.biu_werror(biu_werror),
		.biu_raddr(biu_raddr),
		.biu_renable(biu_renable),
		.biu_rdata(biu_rdata),
		.biu_raccept(biu_raccept),
		.biu_rerror(biu_rerror)
	);

endmodule /* tb_axi4_lite_biu */
