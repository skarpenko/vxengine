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
 * Testbench for VxE AXI switch
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_axi_switch();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	/* Global signals */
	reg		clk;
	reg		nrst;
	/* Incoming request from a client */
	reg		m_rqa_vld;
	reg [43:0]	m_rqa;
	wire		m_rqa_rd;
	reg		m_rqd_vld;
	reg [71:0]	m_rqd;
	wire		m_rqd_rd;
	/* Outgoing response for a client */
	reg		m_rss_rdy;
	wire [8:0]	m_rss;
	wire		m_rss_wr;
	reg		m_rsd_rdy;
	wire [63:0]	m_rsd;
	wire		m_rsd_wr;
	/* Outgoing request to AXI */
	wire [5:0]	biu_awcid;
	wire [39:0]	biu_awaddr;
	wire [63:0]	biu_awdata;
	wire [7:0]	biu_awstrb;
	wire		biu_awvalid;
	reg		biu_awpop;
	wire [5:0]	biu_arcid;
	wire [39:0]	biu_araddr;
	wire		biu_arvalid;
	reg		biu_arpop;
	/* Incoming response on AXI */
	reg [5:0]	biu_bcid;
	reg [1:0]	biu_bresp;
	wire		biu_bready;
	reg		biu_bpush;
	reg [5:0]	biu_rcid;
	reg [63:0]	biu_rdata;
	reg [1:0]	biu_rresp;
	wire		biu_rready;
	reg		biu_rpush;
	/* Current test name */
	reg [31:0]	test_name;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	task wait_pos_clk4;
	begin
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_axi_switch);

		clk = 1;
		nrst = 0;

		m_rqa_vld = 1'b0;
		m_rqd_vld = 1'b0;
		m_rss_rdy = 1'b0;
		m_rsd_rdy = 1'b0;
		biu_awpop = 1'b0;
		biu_arpop = 1'b0;
		biu_bpush = 1'b0;
		biu_rpush = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/*****************/

		/* Enable transmission */
		@(posedge clk)
		begin
			/* Enable requests read */
			biu_awpop <= 1'b1;
			biu_arpop <= 1'b1;
			/* Set ready to receive responses */
			m_rss_rdy <= 1'b1;
			m_rsd_rdy <= 1'b1;
		end


		wait_pos_clk4();


		/* Send write request */
		@(posedge clk)
		begin
			test_name <= "WR00";
			m_rqa_vld <= 1'b1;
			m_rqa <= { 6'hA, 1'b0, 37'hAEAEAEAE};
			m_rqd_vld <= 1'b1;
			m_rqd <= 72'hDADADEDE00;
		end
		@(posedge clk)
		begin
			m_rqa_vld <= 1'b0;
			m_rqd_vld <= 1'b0;
		end


		wait_pos_clk4();


		/* Send read request */
		@(posedge clk)
		begin
			test_name <= "RD00";
			m_rqa_vld <= 1'b1;
			m_rqa <= { 6'hC, 1'b1, 37'hDEDEDEDE};
		end
		@(posedge clk)
		begin
			m_rqa_vld <= 1'b0;
		end


		wait_pos_clk4();


		/* Send write response */
		@(posedge clk)
		begin
			test_name <= "BR00";
			biu_bcid <= 6'hE;
			biu_bresp <= 2'b01;
			biu_bpush <= 1'b1;
		end
		@(posedge clk)
		begin
			biu_bpush <= 1'b0;
		end


		wait_pos_clk4();


		/* Send read response */
		@(posedge clk)
		begin
			test_name <= "RR00";
			biu_rcid <= 6'hD;
			biu_rresp <= 2'b01;
			biu_rdata <= 64'hDEADBEEF_CAFECAFE;
			biu_rpush <= 1'b1;
		end
		@(posedge clk)
		begin
			biu_rpush <= 1'b0;
		end


		wait_pos_clk4();


		/* Clogged read and write request paths */
		@(posedge clk)
		begin
			/* Disable requests read */
			biu_awpop <= 1'b0;
			biu_arpop <= 1'b0;
		end


		wait_pos_clk4();


		/* Send write request */
		@(posedge clk)
		begin
			test_name <= "WR01";
			m_rqa_vld <= 1'b1;
			m_rqa <= { 6'hA, 1'b0, 37'hBEBEBEBE};
			m_rqd_vld <= 1'b1;
			m_rqd <= 72'hDCDCDCDC00;
		end
		@(posedge clk)
		begin
			m_rqa_vld <= 1'b0;
			m_rqd_vld <= 1'b0;
		end


		wait_pos_clk4();


		/* Send read request */
		@(posedge clk)
		begin
			test_name <= "RD01";
			m_rqa_vld <= 1'b1;
			m_rqa <= { 6'hC, 1'b1, 37'hDBDBDBDB};
		end
		@(posedge clk)
		begin
			m_rqa_vld <= 1'b0;
		end


		wait_pos_clk4();


		/* Unclog request paths */
		@(posedge clk)
		begin
			/* Enable requests read */
			biu_awpop <= 1'b1;
			biu_arpop <= 1'b1;
		end


		wait_pos_clk4();


		/* Clogged response paths */
		@(posedge clk)
		begin
			/* Clear ready to receive responses */
			m_rss_rdy <= 1'b0;
			m_rsd_rdy <= 1'b0;
		end


		wait_pos_clk4();


		/* Send write response */
		@(posedge clk)
		begin
			test_name <= "BR01";
			biu_bcid <= 6'hF;
			biu_bresp <= 2'b01;
			biu_bpush <= 1'b1;
		end
		@(posedge clk)
		begin
			biu_bpush <= 1'b0;
		end


		wait_pos_clk4();


		/* Send read response */
		@(posedge clk)
		begin
			test_name <= "RR01";
			biu_rcid <= 6'hA;
			biu_rresp <= 2'b01;
			biu_rdata <= 64'hCAFECAFE_DEADBEEF;
			biu_rpush <= 1'b1;
		end
		@(posedge clk)
		begin
			biu_rpush <= 1'b0;
		end


		wait_pos_clk4();


		/* Unclog response paths */
		@(posedge clk)
		begin
			/* Set ready to receive responses */
			m_rss_rdy <= 1'b1;
			m_rsd_rdy <= 1'b1;
		end


		wait_pos_clk4();


		/*****************/

		#500 $finish;
	end


	/* AXI switch */
	vxe_axi_switch axi_switch(
		.clk(clk),
		.nrst(nrst),
		.i_m_rqa_vld(m_rqa_vld),
		.i_m_rqa(m_rqa),
		.o_m_rqa_rd(m_rqa_rd),
		.i_m_rqd_vld(m_rqd_vld),
		.i_m_rqd(m_rqd),
		.o_m_rqd_rd(m_rqd_rd),
		.i_m_rss_rdy(m_rss_rdy),
		.o_m_rss(m_rss),
		.o_m_rss_wr(m_rss_wr),
		.i_m_rsd_rdy(m_rsd_rdy),
		.o_m_rsd(m_rsd),
		.o_m_rsd_wr(m_rsd_wr),
		.biu_awcid(biu_awcid),
		.biu_awaddr(biu_awaddr),
		.biu_awdata(biu_awdata),
		.biu_awstrb(biu_awstrb),
		.biu_awvalid(biu_awvalid),
		.biu_awpop(biu_awpop),
		.biu_arcid(biu_arcid),
		.biu_araddr(biu_araddr),
		.biu_arvalid(biu_arvalid),
		.biu_arpop(biu_arpop),
		.biu_bcid(biu_bcid),
		.biu_bresp(biu_bresp),
		.biu_bready(biu_bready),
		.biu_bpush(biu_bpush),
		.biu_rcid(biu_rcid),
		.biu_rdata(biu_rdata),
		.biu_rresp(biu_rresp),
		.biu_rready(biu_rready),
		.biu_rpush(biu_rpush)
	);


endmodule /* tb_vxe_axi_switch */
