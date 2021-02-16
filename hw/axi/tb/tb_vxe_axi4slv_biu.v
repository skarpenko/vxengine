/*
 * Copyright (c) 2020-2021 The VxEngine Project. All rights reserved.
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
 * Testbench for AXI4 slave bus interface unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_axi4slv_biu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam ADDR_WIDTH = 32;
	localparam DATA_WIDTH = 32;
	localparam ID_WIDTH = 8;

	reg			clk;
	reg			nrst;
	/* AXI write address channel */
	reg [ID_WIDTH-1:0]	S_AXI4_AWID;
	reg [ADDR_WIDTH-1:0]	S_AXI4_AWADDR;
	reg [7:0]		S_AXI4_AWLEN;
	reg [2:0]		S_AXI4_AWSIZE;
	reg [1:0]		S_AXI4_AWBURST;
	reg			S_AXI4_AWLOCK;
	reg [2:0]		S_AXI4_AWPROT;
	reg			S_AXI4_AWVALID;
	wire			S_AXI4_AWREADY;
	/* AXI write data channel */
	reg [DATA_WIDTH-1:0]	S_AXI4_WDATA;
	reg [DATA_WIDTH/8-1:0]	S_AXI4_WSTRB;
	reg			S_AXI4_WLAST;
	reg			S_AXI4_WVALID;
	wire			S_AXI4_WREADY;
	/* AXI write response channel */
	wire [ID_WIDTH-1:0]	S_AXI4_BID;
	wire [1:0]		S_AXI4_BRESP;
	wire			S_AXI4_BVALID;
	reg			S_AXI4_BREADY;
	/* AXI read address channel */
	reg [ID_WIDTH-1:0]	S_AXI4_ARID;
	reg [ADDR_WIDTH-1:0]	S_AXI4_ARADDR;
	reg [7:0]		S_AXI4_ARLEN;
	reg [2:0]		S_AXI4_ARSIZE;
	reg [1:0]		S_AXI4_ARBURST;
	reg			S_AXI4_ARLOCK;
	reg [2:0]		S_AXI4_ARPROT;
	reg			S_AXI4_ARVALID;
	wire			S_AXI4_ARREADY;
	/* AXI read data channel */
	wire [ID_WIDTH-1:0]	S_AXI4_RID;
	wire [DATA_WIDTH-1:0]	S_AXI4_RDATA;
	wire [1:0]		S_AXI4_RRESP;
	wire			S_AXI4_RLAST;
	wire			S_AXI4_RVALID;
	reg			S_AXI4_RREADY;
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


	/* AXI4 read */
	task axi_read;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data;
	input rready;
	input raccept;
	begin
		@(posedge clk)
		begin
			S_AXI4_ARID <= { {(ID_WIDTH-2){1'b0}}, 2'b01 };
			S_AXI4_ARADDR <= addr;
			S_AXI4_ARVALID <= 1'b1;
			S_AXI4_RREADY <= rready;
			biu_raccept <= raccept;
			biu_rdata <= data;
		end

		@(posedge clk)
		begin
			S_AXI4_ARVALID <= 1'b0;
		end

		@(posedge clk)
		begin
		end
	end
	endtask


	/* AXI4 write */
	task axi_write;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data;
	input bready;
	input waccept;
	begin
		@(posedge clk)
		begin
			S_AXI4_AWID <= { {(ID_WIDTH-2){1'b0}}, 2'b10 };
			S_AXI4_AWADDR <= addr;
			S_AXI4_AWPROT <= 3'b0;
			S_AXI4_AWVALID <= 1'b1;
			S_AXI4_WDATA <= data;
			S_AXI4_WSTRB <= 4'hf;
			S_AXI4_WLAST <= 1'b1;
			S_AXI4_WVALID <= 1'b1;
			S_AXI4_BREADY <= bready;
			biu_waccept <= waccept;
		end

		@(posedge clk)
		begin
			S_AXI4_AWVALID <= 1'b0;
			S_AXI4_WVALID <= 1'b0;
		end

		@(posedge clk)
		begin
		end
	end
	endtask

	/* AXI4 write (address phase only) */
	task axi_write_addr;
	input [ADDR_WIDTH-1:0] addr;
	input bready;
	input waccept;
	begin
		@(posedge clk)
		begin
			S_AXI4_AWID <= { {(ID_WIDTH-2){1'b0}}, 2'b10 };
			S_AXI4_AWADDR <= addr;
			S_AXI4_AWPROT <= 3'b0;
			S_AXI4_AWVALID <= 1'b1;
			S_AXI4_BREADY <= bready;
			biu_waccept <= waccept;
		end

		@(posedge clk)
		begin
			S_AXI4_AWVALID <= 1'b0;
		end

		@(posedge clk)
		begin
		end
	end
	endtask

	/* AXI4 write (data phase only) */
	task axi_write_data;
	input [DATA_WIDTH-1:0] data;
	begin
		@(posedge clk)
		begin
			S_AXI4_WDATA <= data;
			S_AXI4_WSTRB <= 4'hf;
			S_AXI4_WLAST <= 1'b1;
			S_AXI4_WVALID <= 1'b1;
		end

		@(posedge clk)
		begin
			S_AXI4_WVALID <= 1'b0;
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
		$dumpvars(0, tb_vxe_axi4slv_biu);

		clk = 1;
		nrst = 0;

		S_AXI4_AWID = {ID_WIDTH{1'b0}};
		S_AXI4_AWADDR = {ADDR_WIDTH{1'b0}};
		S_AXI4_AWLEN = 8'b0;
		S_AXI4_AWSIZE = 3'b0;
		S_AXI4_AWBURST = 2'b0;
		S_AXI4_AWLOCK = 1'b0;
		S_AXI4_AWPROT = 3'b0;
		S_AXI4_AWVALID = 1'b0;
		S_AXI4_WDATA = {DATA_WIDTH{1'b0}};
		S_AXI4_WSTRB = {DATA_WIDTH/8{1'b0}};
		S_AXI4_WLAST = 1'b0;
		S_AXI4_WVALID = 1'b0;
		S_AXI4_BREADY = 2'b0;
		S_AXI4_ARID = {ID_WIDTH{1'b0}};
		S_AXI4_ARADDR = {ADDR_WIDTH{1'b0}};
		S_AXI4_ARLEN = 8'b0;
		S_AXI4_ARSIZE = 3'b0;
		S_AXI4_ARBURST = 2'b0;
		S_AXI4_ARLOCK = 1'b0;
		S_AXI4_ARPROT = 3'b0;
		S_AXI4_ARVALID = 1'b0;
		S_AXI4_RREADY = 1'b0;
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
			S_AXI4_RREADY <= 1'b1;
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

		axi_write(32'h0000_0010, 32'hf5f6_f7f8, 1'b0, 1'b1);

		wait_pos_clk();

		@(posedge clk)
		begin
			S_AXI4_BREADY <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		axi_write(32'h0000_0020, 32'hf9f8_f7f6, 1'b1, 1'b0);

		wait_pos_clk();

		@(posedge clk)
		begin
			biu_waccept <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		axi_write_addr(32'h0000_0030, 1'b1, 1'b1);
		axi_write_data(32'hf7f7_f7f7);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			S_AXI4_ARLOCK <= 1'b1;
		end

		axi_read(32'h0000_0080, 32'hfafa_dada, 1'b1, 1'b1);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		#500 $finish;
	end


	/* AXI4 slave BIU instance */
	vxe_axi4slv_biu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH)
	) axi4_biu (
		.S_AXI4_ACLK(clk),
		.S_AXI4_ARESETn(nrst),
		/* AXI channels */
		.S_AXI4_AWID(S_AXI4_AWID),
		.S_AXI4_AWADDR(S_AXI4_AWADDR),
		.S_AXI4_AWLEN(S_AXI4_AWLEN),
		.S_AXI4_AWSIZE(S_AXI4_AWSIZE),
		.S_AXI4_AWBURST(S_AXI4_AWBURST),
		.S_AXI4_AWLOCK(S_AXI4_AWLOCK),
		.S_AXI4_AWPROT(S_AXI4_AWPROT),
		.S_AXI4_AWVALID(S_AXI4_AWVALID),
		.S_AXI4_AWREADY(S_AXI4_AWREADY),
		.S_AXI4_WDATA(S_AXI4_WDATA),
		.S_AXI4_WSTRB(S_AXI4_WSTRB),
		.S_AXI4_WLAST(S_AXI4_WLAST),
		.S_AXI4_WVALID(S_AXI4_WVALID),
		.S_AXI4_WREADY(S_AXI4_WREADY),
		.S_AXI4_BID(S_AXI4_BID),
		.S_AXI4_BRESP(S_AXI4_BRESP),
		.S_AXI4_BVALID(S_AXI4_BVALID),
		.S_AXI4_BREADY(S_AXI4_BREADY),
		.S_AXI4_ARID(S_AXI4_ARID),
		.S_AXI4_ARADDR(S_AXI4_ARADDR),
		.S_AXI4_ARLEN(S_AXI4_ARLEN),
		.S_AXI4_ARSIZE(S_AXI4_ARSIZE),
		.S_AXI4_ARBURST(S_AXI4_ARBURST),
		.S_AXI4_ARLOCK(S_AXI4_ARLOCK),
		.S_AXI4_ARPROT(S_AXI4_ARPROT),
		.S_AXI4_ARVALID(S_AXI4_ARVALID),
		.S_AXI4_ARREADY(S_AXI4_ARREADY),
		.S_AXI4_RDATA(S_AXI4_RDATA),
		.S_AXI4_RID(S_AXI4_RID),
		.S_AXI4_RRESP(S_AXI4_RRESP),
		.S_AXI4_RLAST(S_AXI4_RLAST),
		.S_AXI4_RVALID(S_AXI4_RVALID),
		.S_AXI4_RREADY(S_AXI4_RREADY),
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

endmodule /* tb_vxe_axi4slv_biu */
