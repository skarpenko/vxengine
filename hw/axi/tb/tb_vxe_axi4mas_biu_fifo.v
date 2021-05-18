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
 * Testbench for AXI4 master bus interface unit using FIFOs for in and out
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_axi4mas_biu_fifo();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam ADDR_WIDTH = 32;
	localparam DATA_WIDTH = 32;
	localparam ID_WIDTH = 8;
	localparam CID_WIDTH = 8;
	localparam FIFO_AW_WIDTH = CID_WIDTH + ADDR_WIDTH + DATA_WIDTH
					+ DATA_WIDTH/8;
	localparam FIFO_B_WIDTH = CID_WIDTH + 2;
	localparam FIFO_AR_WIDTH = CID_WIDTH + ADDR_WIDTH;
	localparam FIFO_R_WIDTH = CID_WIDTH + DATA_WIDTH + 2;


	reg				clk;
	reg				nrst;
	/* AXI write address channel */
	wire [ID_WIDTH-1:0]		M_AXI4_AWID;
	wire [ADDR_WIDTH-1:0]		M_AXI4_AWADDR;
	wire [7:0]			M_AXI4_AWLEN;
	wire [2:0]			M_AXI4_AWSIZE;
	wire [1:0]			M_AXI4_AWBURST;
	wire				M_AXI4_AWLOCK;
	wire [3:0]			M_AXI4_AWCACHE;
	wire [2:0]			M_AXI4_AWPROT;
	wire				M_AXI4_AWVALID;
	wire				M_AXI4_AWREADY;
	/* AXI write data channel */
	wire [DATA_WIDTH-1:0]		M_AXI4_WDATA;
	wire [DATA_WIDTH/8-1:0]		M_AXI4_WSTRB;
	wire				M_AXI4_WLAST;
	wire				M_AXI4_WVALID;
	wire				M_AXI4_WREADY;
	/* AXI write response channel */
	reg [ID_WIDTH-1:0]		M_AXI4_BID;
	reg [1:0]			M_AXI4_BRESP;
	reg				M_AXI4_BVALID;
	wire				M_AXI4_BREADY;
	/* AXI read address channel */
	wire [ID_WIDTH-1:0]		M_AXI4_ARID;
	wire [ADDR_WIDTH-1:0]		M_AXI4_ARADDR;
	wire [7:0]			M_AXI4_ARLEN;
	wire [2:0]			M_AXI4_ARSIZE;
	wire [1:0]			M_AXI4_ARBURST;
	wire				M_AXI4_ARLOCK;
	wire [3:0]			M_AXI4_ARCACHE;
	wire [2:0]			M_AXI4_ARPROT;
	wire				M_AXI4_ARVALID;
	wire				M_AXI4_ARREADY;
	/* AXI read data channel */
	reg [ID_WIDTH-1:0]		M_AXI4_RID;
	reg [DATA_WIDTH-1:0]		M_AXI4_RDATA;
	reg [1:0]			M_AXI4_RRESP;
	wire				M_AXI4_RLAST;
	reg				M_AXI4_RVALID;
	wire				M_AXI4_RREADY;
	/* BIU interface write path */
	wire [CID_WIDTH-1:0]		biu_awcid;
	wire [ADDR_WIDTH-1:0]		biu_awaddr;
	wire [DATA_WIDTH-1:0]		biu_awdata;
	wire [DATA_WIDTH/8-1:0]		biu_awstrb;
	wire				biu_awvalid;
	wire				biu_awpop;
	wire [CID_WIDTH-1:0]		biu_bcid;
	wire [1:0]			biu_bresp;
	wire				biu_bready;
	wire				biu_bpush;
	/* BIU interface read path */
	wire [CID_WIDTH-1:0]		biu_arcid;
	wire [ADDR_WIDTH-1:0]		biu_araddr;
	wire				biu_arvalid;
	wire				biu_arpop;
	wire [CID_WIDTH-1:0]		biu_rcid;
	wire [DATA_WIDTH-1:0]		biu_rdata;
	wire [1:0]			biu_rresp;
	wire				biu_rready;
	wire				biu_rpush;
	/* FIFOs interface */
	reg [FIFO_AW_WIDTH-1:0]		fifo_aw_data_in;
	wire [FIFO_AW_WIDTH-1:0]	fifo_aw_data_out;
	wire				fifo_aw_rd;
	reg				fifo_aw_wr;
	wire				fifo_aw_in_rdy;
	wire				fifo_aw_out_vld;
	wire [FIFO_B_WIDTH-1:0]		fifo_b_data_in;
	wire [FIFO_B_WIDTH-1:0]		fifo_b_data_out;
	reg				fifo_b_rd;
	wire				fifo_b_wr;
	wire				fifo_b_in_rdy;
	wire				fifo_b_out_vld;
	reg [FIFO_AR_WIDTH-1:0]		fifo_ar_data_in;
	wire [FIFO_AR_WIDTH-1:0]	fifo_ar_data_out;
	wire				fifo_ar_rd;
	reg				fifo_ar_wr;
	wire				fifo_ar_in_rdy;
	wire				fifo_ar_out_vld;
	wire [FIFO_R_WIDTH-1:0]		fifo_r_data_in;
	wire [FIFO_R_WIDTH-1:0]		fifo_r_data_out;
	reg				fifo_r_rd;
	wire				fifo_r_wr;
	wire				fifo_r_in_rdy;
	wire				fifo_r_out_vld;

	/* Assignments */
	assign { biu_awcid, biu_awaddr, biu_awdata, biu_awstrb } = fifo_aw_data_out;
	assign biu_awvalid = fifo_aw_out_vld;
	assign fifo_aw_rd = biu_awpop;
	assign fifo_b_data_in = { biu_bcid, biu_bresp};
	assign biu_bready = fifo_b_in_rdy;
	assign fifo_b_wr = biu_bpush;
	assign { biu_arcid, biu_araddr } = fifo_ar_data_out;
	assign biu_arvalid = fifo_ar_out_vld;
	assign fifo_ar_rd = biu_arpop;
	assign fifo_r_data_in = { biu_rcid, biu_rresp, biu_rdata};
	assign biu_rready = fifo_r_in_rdy;
	assign fifo_r_wr = biu_rpush;

	/* Traffic control */
	reg rtraf_gen;	/* Generate read response traffic */
	reg btraf_gen;	/* Generate write response traffic */


	always
		#HCLK clk = !clk;


	/* FIFO read */
	task fifo_read;
	input [CID_WIDTH-1:0] cid;
	input [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge clk)
		begin
			fifo_ar_data_in <= { cid, addr };
			fifo_ar_wr <= 1'b1;
		end

		@(posedge clk)
		begin
			fifo_ar_wr <= 1'b0;
		end

		@(posedge clk);
	end
	endtask


	/* FIFO write */
	task fifo_write;
	input [CID_WIDTH-1:0] cid;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data;
	input [DATA_WIDTH/8-1:0] wstrb;
	begin
		@(posedge clk)
		begin
			fifo_aw_data_in <= { cid, addr, data, wstrb };
			fifo_aw_wr <= 1'b1;
		end

		@(posedge clk)
		begin
			fifo_aw_wr <= 1'b0;
		end

		@(posedge clk);
	end
	endtask


	task wait_pos_clk;
		@(posedge clk);
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_axi4mas_biu_fifo);

		clk = 1;
		nrst = 0;

		fifo_aw_data_in = {FIFO_AW_WIDTH{1'b0}};
		fifo_aw_wr = 1'b0;
		fifo_ar_data_in = {FIFO_AR_WIDTH{1'b0}};
		fifo_ar_wr = 1'b0;
		fifo_r_rd = 1'b1;
		fifo_b_rd = 1'b1;
		rtraf_gen = 1'b0;
		btraf_gen = 1'b0;


		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();


		/* Write transaction */
		fifo_write(8'hfe, 32'h0000_000c, 32'hfefe_fafa, 4'b1111);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Sequence of writes */
		fifo_write(8'hf1, 32'h0000_00c1, 32'hfefe_fa01, 4'b1111);
		fifo_write(8'hf2, 32'h0000_00c2, 32'hfefe_fa02, 4'b1111);
		fifo_write(8'hf3, 32'h0000_00c3, 32'hfefe_fa03, 4'b1111);
		fifo_write(8'hf4, 32'h0000_00c4, 32'hfefe_fa04, 4'b1111);
		fifo_write(8'hf5, 32'h0000_00c5, 32'hfefe_fa05, 4'b1111);
		fifo_write(8'hf6, 32'h0000_00c6, 32'hfefe_fa06, 4'b1111);
		fifo_write(8'hf7, 32'h0000_00c7, 32'hfefe_fa07, 4'b1111);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Sequence of non-stop writes */
		@(posedge clk)
		begin
			fifo_aw_data_in <= { 8'hf1, 32'h0000_00c1, 32'hfefe_fa01, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_aw_data_in <= { 8'hf2, 32'h0000_00c2, 32'hfefe_fa02, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_aw_data_in <= { 8'hf3, 32'h0000_00c3, 32'hfefe_fa03, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_aw_data_in <= { 8'hf4, 32'h0000_00c4, 32'hfefe_fa04, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_aw_data_in <= { 8'hf5, 32'h0000_00c5, 32'hfefe_fa05, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_aw_data_in <= { 8'hf6, 32'h0000_00c6, 32'hfefe_fa06, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_aw_data_in <= { 8'hf7, 32'h0000_00c7, 32'hfefe_fa07, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_aw_wr <= 1'b0;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Read transaction */
		fifo_read(8'hfe, 32'h0000_000c);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Sequence of reads */
		fifo_read(8'hf1, 32'h0000_00c1);
		fifo_read(8'hf2, 32'h0000_00c2);
		fifo_read(8'hf3, 32'h0000_00c3);
		fifo_read(8'hf4, 32'h0000_00c4);
		fifo_read(8'hf5, 32'h0000_00c5);
		fifo_read(8'hf6, 32'h0000_00c6);
		fifo_read(8'hf7, 32'h0000_00c7);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Sequence of non-stop reads */
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'hf1, 32'h0000_00c1 };
			fifo_ar_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'hf2, 32'h0000_00c2 };
			fifo_ar_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'hf3, 32'h0000_00c3 };
			fifo_ar_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'hf4, 32'h0000_00c4 };
			fifo_ar_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'hf5, 32'h0000_00c5 };
			fifo_ar_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'hf6, 32'h0000_00c6 };
			fifo_ar_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'hf7, 32'h0000_00c7 };
			fifo_ar_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_wr <= 1'b0;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Non-stop reads and writes */
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'ha1, 32'h0000_a0c1 };
			fifo_ar_wr <= 1'b1;
			fifo_aw_data_in <= { 8'hb1, 32'h0000_b0c1, 32'haafe_fa01, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'ha2, 32'h0000_a0c2 };
			fifo_ar_wr <= 1'b1;
			fifo_aw_data_in <= { 8'hb2, 32'h0000_b0c2, 32'haafe_fa02, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'ha3, 32'h0000_a0c3 };
			fifo_ar_wr <= 1'b1;
			fifo_aw_data_in <= { 8'hb3, 32'h0000_b0c3, 32'haafe_fa03, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'ha4, 32'h0000_a0c4 };
			fifo_ar_wr <= 1'b1;
			fifo_aw_data_in <= { 8'hb4, 32'h0000_b0c4, 32'haafe_fa04, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'ha5, 32'h0000_a0c5 };
			fifo_ar_wr <= 1'b1;
			fifo_aw_data_in <= { 8'hb5, 32'h0000_b0c5, 32'haafe_fa05, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'ha6, 32'h0000_a0c6 };
			fifo_ar_wr <= 1'b1;
			fifo_aw_data_in <= { 8'hb6, 32'h0000_b0c6, 32'haafe_fa06, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_data_in <= { 8'ha7, 32'h0000_a0c7 };
			fifo_ar_wr <= 1'b1;
			fifo_aw_data_in <= { 8'hb7, 32'h0000_b0c7, 32'haafe_fa07, 4'b1111 };
			fifo_aw_wr <= 1'b1;
		end
		@(posedge clk)
		begin
			fifo_ar_wr <= 1'b0;
			fifo_aw_wr <= 1'b0;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Read response traffic test */
		@(posedge clk)
		begin
			fifo_r_rd <= 1'b0;
			rtraf_gen <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
			fifo_r_rd <= 1'b1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
			rtraf_gen <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Write response traffic test */
		@(posedge clk)
		begin
			fifo_b_rd <= 1'b0;
			btraf_gen <= 1'b1;
		end

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
			fifo_b_rd <= 1'b1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
			btraf_gen <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
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

	/* FIFO for AW channel */
	vxe_fifo #(
		.DATA_WIDTH(FIFO_AW_WIDTH)
	) fifo_aw (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_aw_data_in),
		.data_out(fifo_aw_data_out),
		.rd(fifo_aw_rd),
		.wr(fifo_aw_wr),
		.in_rdy(fifo_aw_in_rdy),
		.out_vld(fifo_aw_out_vld)
	);

	/* FIFO for B channel */
	vxe_fifo #(
		.DATA_WIDTH(FIFO_B_WIDTH)
	) fifo_b (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_b_data_in),
		.data_out(fifo_b_data_out),
		.rd(fifo_b_rd),
		.wr(fifo_b_wr),
		.in_rdy(fifo_b_in_rdy),
		.out_vld(fifo_b_out_vld)
	);

	/* FIFO for AR channel */
	vxe_fifo #(
		.DATA_WIDTH(FIFO_AR_WIDTH)
	) fifo_ar (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_ar_data_in),
		.data_out(fifo_ar_data_out),
		.rd(fifo_ar_rd),
		.wr(fifo_ar_wr),
		.in_rdy(fifo_ar_in_rdy),
		.out_vld(fifo_ar_out_vld)
	);

	/* FIFO for R channel */
	vxe_fifo #(
		.DATA_WIDTH(FIFO_R_WIDTH)
	) fifo_r (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_r_data_in),
		.data_out(fifo_r_data_out),
		.rd(fifo_r_rd),
		.wr(fifo_r_wr),
		.in_rdy(fifo_r_in_rdy),
		.out_vld(fifo_r_out_vld)
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
				wid <= M_AXI4_AWID;

			if(M_AXI4_WVALID)
				wdata <= M_AXI4_WDATA;

			wr[0] <= M_AXI4_AWVALID;
			wr[1] <= M_AXI4_WVALID;
		end
	end

	reg bstop;
	reg [ID_WIDTH-1:0] bidcntr;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			M_AXI4_BVALID <= 1'b0;
			bstop <= 1'b0;
			bidcntr <= {{ID_WIDTH-3{1'b0}}, 3'b100};
		end
		else if(btraf_gen == 1'b0)
		begin
			if(wr == 2'b11)
			begin
				M_AXI4_BID <= wid;
				M_AXI4_BRESP <= 2'b00;
				M_AXI4_BVALID <= 1'b1;
			end
			else if(M_AXI4_BREADY == 1'b1)
				M_AXI4_BVALID <= 1'b0;
		end
		else
		begin
			if(bstop == 1'b0)
			begin
				M_AXI4_BID <= bidcntr;
				M_AXI4_BRESP <= 2'b00;
				M_AXI4_BVALID <= 1'b1;
				bidcntr <= bidcntr + 3'b100;
				if(M_AXI4_BREADY == 1'b0)
					bstop <= 1'b1;
			end
			else if(bstop == 1'b1)
			begin
				if(M_AXI4_BREADY == 1'b1)
					bstop <= 1'b0;
			end
		end
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
				rid <= M_AXI4_ARID;

			rd <= M_AXI4_ARVALID;
		end
	end

	reg rstop;
	reg [DATA_WIDTH-1:0] rcntr;
	reg [ID_WIDTH-1:0] ridcntr;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			M_AXI4_RVALID <= 1'b0;
			rstop <= 1'b0;
			rcntr <= {{DATA_WIDTH-1{1'b0}}, 1'b1};
			ridcntr <= {{ID_WIDTH-1{1'b0}}, 1'b1};
		end
		else if(rtraf_gen == 1'b0)
		begin
			if(rd == 1'b1)
			begin
				M_AXI4_RID <= rid;
				M_AXI4_RRESP <= 2'b00;
				M_AXI4_RDATA <= wdata;
				M_AXI4_RVALID <= 1'b1;
			end
			else if(M_AXI4_RREADY == 1'b1)
				M_AXI4_RVALID <= 1'b0;
		end
		else
		begin
			if(rstop == 1'b0)
			begin
				M_AXI4_RID <= ridcntr;
				M_AXI4_RRESP <= 2'b00;
				M_AXI4_RDATA <= rcntr;
				M_AXI4_RVALID <= 1'b1;
				rcntr <= rcntr + 1'b1;
				ridcntr <= ridcntr + 1'b1;
				if(M_AXI4_RREADY == 1'b0)
					rstop <= 1'b1;
			end
			else if(rstop == 1'b1)
			begin
				if(M_AXI4_RREADY == 1'b1)
					rstop <= 1'b0;
			end
		end
	end


endmodule /* tb_vxe_axi4mas_biu_fifo */
