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
 * Testbench for AXI4 master bus interface unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_axi4mas_biu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam ADDR_WIDTH = 32;
	localparam DATA_WIDTH = 32;
	localparam ID_WIDTH = 8;
	localparam CID_WIDTH = 8;

	reg			clk;
	reg			nrst;
	/* AXI write address channel */
	wire [ID_WIDTH-1:0]	M_AXI4_AWID;
	wire [ADDR_WIDTH-1:0]	M_AXI4_AWADDR;
	wire [7:0]		M_AXI4_AWLEN;
	wire [2:0]		M_AXI4_AWSIZE;
	wire [1:0]		M_AXI4_AWBURST;
	wire			M_AXI4_AWLOCK;
	wire [3:0]		M_AXI4_AWCACHE;
	wire [2:0]		M_AXI4_AWPROT;
	wire			M_AXI4_AWVALID;
	wire			M_AXI4_AWREADY;
	/* AXI write data channel */
	wire [DATA_WIDTH-1:0]	M_AXI4_WDATA;
	wire [DATA_WIDTH/8-1:0]	M_AXI4_WSTRB;
	wire			M_AXI4_WLAST;
	wire			M_AXI4_WVALID;
	wire			M_AXI4_WREADY;
	/* AXI write response channel */
	reg [ID_WIDTH-1:0]	M_AXI4_BID;
	reg [1:0]		M_AXI4_BRESP;
	reg			M_AXI4_BVALID;
	wire			M_AXI4_BREADY;
	/* AXI read address channel */
	wire [ID_WIDTH-1:0]	M_AXI4_ARID;
	wire [ADDR_WIDTH-1:0]	M_AXI4_ARADDR;
	wire [7:0]		M_AXI4_ARLEN;
	wire [2:0]		M_AXI4_ARSIZE;
	wire [1:0]		M_AXI4_ARBURST;
	wire			M_AXI4_ARLOCK;
	wire [3:0]		M_AXI4_ARCACHE;
	wire [2:0]		M_AXI4_ARPROT;
	wire			M_AXI4_ARVALID;
	wire			M_AXI4_ARREADY;
	/* AXI read data channel */
	reg [ID_WIDTH-1:0]	M_AXI4_RID;
	reg [DATA_WIDTH-1:0]	M_AXI4_RDATA;
	reg [1:0]		M_AXI4_RRESP;
	wire			M_AXI4_RLAST;
	reg			M_AXI4_RVALID;
	wire			M_AXI4_RREADY;
	/* BIU interface write path */
	reg [CID_WIDTH-1:0]	biu_awcid;
	reg [ADDR_WIDTH-1:0]	biu_awaddr;
	reg [DATA_WIDTH-1:0]	biu_awdata;
	reg [DATA_WIDTH/8-1:0]	biu_awstrb;
	reg			biu_awvalid;
	wire			biu_awpop;
	wire [CID_WIDTH-1:0]	biu_bcid;
	wire [1:0]		biu_bresp;
	reg			biu_bready;
	wire			biu_bpush;
	/* BIU interface read path */
	reg [CID_WIDTH-1:0]	biu_arcid;
	reg [ADDR_WIDTH-1:0]	biu_araddr;
	reg			biu_arvalid;
	wire			biu_arpop;
	wire [CID_WIDTH-1:0]	biu_rcid;
	wire [DATA_WIDTH-1:0]	biu_rdata;
	wire [1:0]		biu_rresp;
	reg			biu_rready;
	wire			biu_rpush;


	always
		#HCLK clk = !clk;


	/* BIU read */
	task biu_read;
	input [CID_WIDTH-1:0] cid;
	input [ADDR_WIDTH-1:0] addr;
	input rready;
	begin
		@(posedge clk)
		begin
			biu_arcid <= cid;
			biu_araddr <= addr;
			biu_rready <= rready;
			biu_arvalid <= 1'b1;
		end

		@(posedge clk)
		begin
			biu_arvalid <= 1'b0;
		end

		@(posedge clk)
		begin
		end
	end
	endtask


	/* BIU write */
	task biu_write;
	input [CID_WIDTH-1:0] cid;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data;
	input bready;
	begin
		@(posedge clk)
		begin
			biu_awcid <= cid;
			biu_awaddr <= addr;
			biu_awdata <= data;
			biu_bready <= bready;
			biu_awvalid <= 1'b1;
		end

		@(posedge clk)
		begin
			biu_awvalid <= 1'b0;
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
		$dumpvars(0, tb_vxe_axi4mas_biu);

		clk = 1;
		nrst = 0;

		biu_awcid = {CID_WIDTH{1'b0}};
		biu_awaddr = {ADDR_WIDTH{1'b0}};
		biu_awdata = {DATA_WIDTH{1'b0}};
		biu_awstrb = {DATA_WIDTH/8{1'b0}};
		biu_awvalid = 1'b0;
		biu_bready = 1'b1;
		biu_arcid = {CID_WIDTH{1'b0}};
		biu_araddr = {ADDR_WIDTH{1'b0}};
		biu_arvalid = 1'b0;
		biu_rready = 1'b1;


		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();

		/* Write transaction */
		biu_write(8'hfe, 32'h0000_000c, 32'hfefe_fafa, 1'b1);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/* Read transaction */
		biu_read(8'hfa, 32'h0000_000b, 1'b1);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/* Write transaction, not ready to accept response */
		biu_write(8'hfc, 32'h0000_f00c, 32'hdede_dada, 1'b0);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/* Read transaction, not ready to accept response */
		biu_read(8'hfd, 32'h0000_f00b, 1'b0);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/* Accept write response */
		@(posedge clk) biu_bready <= 1'b1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/* Accept read response */
		@(posedge clk) biu_rready <= 1'b1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		#500 $finish;
	end


	/* AXI4 master BIU instance */
	vxe_axi4mas_biu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.CID_WIDTH(CID_WIDTH)
	) axi4_biu (
		.M_AXI4_ACLK(clk),
		.M_AXI4_ARESETn(nrst),
		/* AXI channels */
		.M_AXI4_AWID(M_AXI4_AWID),
		.M_AXI4_AWADDR(M_AXI4_AWADDR),
		.M_AXI4_AWLEN(M_AXI4_AWLEN),
		.M_AXI4_AWSIZE(M_AXI4_AWSIZE),
		.M_AXI4_AWBURST(M_AXI4_AWBURST),
		.M_AXI4_AWLOCK(M_AXI4_AWLOCK),
		.M_AXI4_AWCACHE(M_AXI4_AWCACHE),
		.M_AXI4_AWPROT(M_AXI4_AWPROT),
		.M_AXI4_AWVALID(M_AXI4_AWVALID),
		.M_AXI4_AWREADY(M_AXI4_AWREADY),
		.M_AXI4_WDATA(M_AXI4_WDATA),
		.M_AXI4_WSTRB(M_AXI4_WSTRB),
		.M_AXI4_WLAST(M_AXI4_WLAST),
		.M_AXI4_WVALID(M_AXI4_WVALID),
		.M_AXI4_WREADY(M_AXI4_WREADY),
		.M_AXI4_BID(M_AXI4_BID),
		.M_AXI4_BRESP(M_AXI4_BRESP),
		.M_AXI4_BVALID(M_AXI4_BVALID),
		.M_AXI4_BREADY(M_AXI4_BREADY),
		.M_AXI4_ARID(M_AXI4_ARID),
		.M_AXI4_ARADDR(M_AXI4_ARADDR),
		.M_AXI4_ARLEN(M_AXI4_ARLEN),
		.M_AXI4_ARSIZE(M_AXI4_ARSIZE),
		.M_AXI4_ARBURST(M_AXI4_ARBURST),
		.M_AXI4_ARLOCK(M_AXI4_ARLOCK),
		.M_AXI4_ARCACHE(M_AXI4_ARCACHE),
		.M_AXI4_ARPROT(M_AXI4_ARPROT),
		.M_AXI4_ARVALID(M_AXI4_ARVALID),
		.M_AXI4_ARREADY(M_AXI4_ARREADY),
		.M_AXI4_RID(M_AXI4_RID),
		.M_AXI4_RDATA(M_AXI4_RDATA),
		.M_AXI4_RRESP(M_AXI4_RRESP),
		.M_AXI4_RLAST(M_AXI4_RLAST),
		.M_AXI4_RVALID(M_AXI4_RVALID),
		.M_AXI4_RREADY(M_AXI4_RREADY),
		/* BIU interface */
		.biu_awcid(biu_awcid),
		.biu_awaddr(biu_awaddr),
		.biu_awdata(biu_awdata),
		.biu_awstrb(biu_awstrb),
		.biu_awvalid(biu_awvalid),
		.biu_awpop(biu_awpop),
		.biu_bcid(biu_bcid),
		.biu_bresp(biu_bresp),
		.biu_bready(biu_bready),
		.biu_bpush(biu_bpush),
		.biu_arcid(biu_arcid),
		.biu_araddr(biu_araddr),
		.biu_arvalid(biu_arvalid),
		.biu_arpop(biu_arpop),
		.biu_rcid(biu_rcid),
		.biu_rdata(biu_rdata),
		.biu_rresp(biu_rresp),
		.biu_rready(biu_rready),
		.biu_rpush(biu_rpush)
	);


	/* Simple AXI4 logic */
	reg [ID_WIDTH-1:0]	wid;
	reg [ID_WIDTH-1:0]	rid;
	reg [DATA_WIDTH-1:0]	wdata;
	reg [1:0]		wr;
	reg			rd;

	assign M_AXI4_AWREADY = 1'b1;
	assign M_AXI4_WREADY = 1'b1;
	assign M_AXI4_ARREADY = 1'b1;
	assign M_AXI4_RLAST = 1'b1;

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			wr <= 2'b00;
		end
		else
		begin
			if(M_AXI4_AWVALID)
			begin
				wr[0] <= 1'b1;
				wid <= M_AXI4_AWID;
			end

			if(M_AXI4_WVALID)
			begin
				wr[1] <= 1'b1;
				wdata <= M_AXI4_WDATA;
			end

			if(wr == 2'b11)
				wr <= 2'b00;
		end
	end

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			M_AXI4_BVALID <= 1'b0;
		end
		else if(wr == 2'b11)
		begin
			M_AXI4_BID <= wid;
			M_AXI4_BRESP <= 2'b00;
			M_AXI4_BVALID <= 1'b1;
		end
		else if(M_AXI4_BREADY == 1'b1)
			M_AXI4_BVALID <= 1'b0;
	end

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			rd <= 1'b0;
		end
		else
		begin
			if(M_AXI4_ARVALID)
			begin
				rd <= 1'b1;
				rid <= M_AXI4_ARID;
			end

			if(rd == 1'b1)
				rd <= 1'b0;
		end
	end

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			M_AXI4_RVALID <= 1'b0;
		end
		else if(rd == 1'b1)
		begin
			M_AXI4_RID <= rid;
			M_AXI4_RRESP <= 2'b00;
			M_AXI4_RDATA <= wdata;
			M_AXI4_RVALID <= 1'b1;
		end
		else if(M_AXI4_RREADY == 1'b1)
			M_AXI4_RVALID <= 1'b0;
	end


endmodule /* tb_vxe_axi4mas_biu */
