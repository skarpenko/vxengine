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
 * Testbench for VxE Memory Hub (set of simple routing tests)
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_mem_hub_simple();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	/* Global signals */
	reg		clk;
	reg		nrst;
	/** CU **/
	/* Master port select */
	reg		cu_m_sel;
	/* Request channel */
	wire		cu_rqa_rdy;
	reg [43:0]	cu_rqa;
	reg		cu_rqa_wr;
	/* Response channel */
	wire		cu_rss_vld;
	wire [8:0]	cu_rss;
	reg		cu_rss_rd;
	wire		cu_rsd_vld;
	wire [63:0]	cu_rsd;
	reg		cu_rsd_rd;
	/** VPU0 **/
	/* Request channel */
	wire		vpu0_rqa_rdy;
	reg [43:0]	vpu0_rqa;
	reg		vpu0_rqa_wr;
	wire		vpu0_rqd_rdy;
	reg [71:0]	vpu0_rqd;
	reg		vpu0_rqd_wr;
	/* Response channel */
	wire		vpu0_rss_vld;
	wire [8:0]	vpu0_rss;
	reg		vpu0_rss_rd;
	wire		vpu0_rsd_vld;
	wire [63:0]	vpu0_rsd;
	reg		vpu0_rsd_rd;
	/** VPU1 **/
	/* Request channel */
	wire		vpu1_rqa_rdy;
	reg [43:0]	vpu1_rqa;
	reg		vpu1_rqa_wr;
	wire		vpu1_rqd_rdy;
	reg [71:0]	vpu1_rqd;
	reg		vpu1_rqd_wr;
	/* Response channel */
	wire		vpu1_rss_vld;
	wire [8:0]	vpu1_rss;
	reg		vpu1_rss_rd;
	wire		vpu1_rsd_vld;
	wire [63:0]	vpu1_rsd;
	reg		vpu1_rsd_rd;
	/** Master port 0 **/
	/* Request channel */
	wire		m0_rqa_vld;
	wire [43:0]	m0_rqa;
	reg		m0_rqa_rd;
	wire		m0_rqd_vld;
	wire [71:0]	m0_rqd;
	reg		m0_rqd_rd;
	/* Response channel */
	wire		m0_rss_rdy;
	reg [8:0]	m0_rss;
	reg		m0_rss_wr;
	wire		m0_rsd_rdy;
	reg [63:0]	m0_rsd;
	reg		m0_rsd_wr;
	/** Master port 1 **/
	/* Request channel */
	wire		m1_rqa_vld;
	wire [43:0]	m1_rqa;
	reg		m1_rqa_rd;
	wire		m1_rqd_vld;
	wire [71:0]	m1_rqd;
	reg		m1_rqd_rd;
	/* Response channel */
	wire		m1_rss_rdy;
	reg [8:0]	m1_rss;
	reg		m1_rss_wr;
	wire		m1_rsd_rdy;
	reg [63:0]	m1_rsd;
	reg		m1_rsd_wr;


	/*** FIFO connection wires ***/

	/** CU **/
	/* Request channel */
	wire		w_cu_rqa_vld;
	wire [43:0]	w_cu_rqa;
	wire		w_cu_rqa_rd;
	/* Response channel */
	wire		w_cu_rss_rdy;
	wire [8:0]	w_cu_rss;
	wire		w_cu_rss_wr;
	wire		w_cu_rsd_rdy;
	wire [63:0]	w_cu_rsd;
	wire		w_cu_rsd_wr;
	/** VPU0 **/
	/* Request channel */
	wire		w_vpu0_rqa_vld;
	wire [43:0]	w_vpu0_rqa;
	wire		w_vpu0_rqa_rd;
	wire		w_vpu0_rqd_vld;
	wire [71:0]	w_vpu0_rqd;
	wire		w_vpu0_rqd_rd;
	/* Response channel */
	wire		w_vpu0_rss_rdy;
	wire [8:0]	w_vpu0_rss;
	wire		w_vpu0_rss_wr;
	wire		w_vpu0_rsd_rdy;
	wire [63:0]	w_vpu0_rsd;
	wire		w_vpu0_rsd_wr;
	/** VPU1 **/
	/* Request channel */
	wire		w_vpu1_rqa_vld;
	wire [43:0]	w_vpu1_rqa;
	wire		w_vpu1_rqa_rd;
	wire		w_vpu1_rqd_vld;
	wire [71:0]	w_vpu1_rqd;
	wire		w_vpu1_rqd_rd;
	/* Response channel */
	wire		w_vpu1_rss_rdy;
	wire [8:0]	w_vpu1_rss;
	wire		w_vpu1_rss_wr;
	wire		w_vpu1_rsd_rdy;
	wire [63:0]	w_vpu1_rsd;
	wire		w_vpu1_rsd_wr;
	/** Master port 0 **/
	/* Request channel */
	wire		w_m0_rqa_rdy;
	wire [43:0]	w_m0_rqa;
	wire		w_m0_rqa_wr;
	wire		w_m0_rqd_rdy;
	wire [71:0]	w_m0_rqd;
	wire		w_m0_rqd_wr;
	/* Response channel */
	wire		w_m0_rss_vld;
	wire [8:0]	w_m0_rss;
	wire		w_m0_rss_rd;
	wire		w_m0_rsd_vld;
	wire [63:0]	w_m0_rsd;
	wire		w_m0_rsd_rd;
	/** Master port 1 **/
	/* Request channel */
	wire		w_m1_rqa_rdy;
	wire [43:0]	w_m1_rqa;
	wire		w_m1_rqa_wr;
	wire		w_m1_rqd_rdy;
	wire [71:0]	w_m1_rqd;
	wire		w_m1_rqd_wr;
	/* Response channel */
	wire		w_m1_rss_vld;
	wire [8:0]	w_m1_rss;
	wire		w_m1_rss_rd;
	wire		w_m1_rsd_vld;
	wire [63:0]	w_m1_rsd;
	wire		w_m1_rsd_rd;

	/* Test name */
	reg [0:47]	test_name;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	task wait_pos_clk4;
	begin
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
	end
	endtask


	task wait_pos_clk8;
	begin
		wait_pos_clk4();
		wait_pos_clk4();
	end
	endtask


	task cu_set_msel;
	input m;
	begin
		@(posedge clk)
			cu_m_sel = m;
	end
	endtask


	task cu_send_req;
	input en;
	input [36:0] addr;
	begin
		@(posedge clk)
		begin
			/*          client thread  arg   rnw   addr */
			cu_rqa <= { 2'b00, 3'b000, 1'b0, 1'b1, addr };
			cu_rqa_wr <= en;
		end
	end
	endtask


	task cu_recv_res;
	input en;
	begin
		@(posedge clk)
		begin
			cu_rss_rd <= en;
			cu_rsd_rd <= en;
		end
	end
	endtask


	task vpu0_send_req;
	input en;
	input [36:0] addr;
	input arg;
	input rnw;
	input [7:0] be;
	input [63:0] data;
	begin
		@(posedge clk)
		begin
			/*            client thread  arg  rnw   addr */
			vpu0_rqa <= { 2'b01, 3'b000, arg, rnw, addr };
			vpu0_rqa_wr <= en;
			vpu0_rqd_wr <= en && ~rnw;
			if(~rnw)
				vpu0_rqd <= { be, data };
		end
	end
	endtask


	task vpu0_recv_res;
	input en;
	begin
		@(posedge clk)
		begin
			vpu0_rss_rd <= en;
			vpu0_rsd_rd <= en;
		end
	end
	endtask


	task vpu1_send_req;
	input en;
	input [36:0] addr;
	input arg;
	input rnw;
	input [7:0] be;
	input [63:0] data;
	begin
		@(posedge clk)
		begin
			/*            client thread  arg  rnw   addr */
			vpu1_rqa <= { 2'b10, 3'b000, arg, rnw, addr };
			vpu1_rqa_wr <= en;
			vpu1_rqd_wr <= en && ~rnw;
			if(~rnw)
				vpu1_rqd <= { be, data };
		end
	end
	endtask


	task vpu1_recv_res;
	input en;
	begin
		@(posedge clk)
		begin
			vpu1_rss_rd <= en;
			vpu1_rsd_rd <= en;
		end
	end
	endtask


	task m0_send_res;
	input en;
	input [1:0] client;
	input [1:0] err;
	input rnw;
	input [63:0] data;
	begin
		@(posedge clk)
		begin
			/*          client  thread  arg   rnw  err */
			m0_rss <= { client, 3'b000, 1'b0, rnw, err };
			m0_rss_wr <= en;
			m0_rsd_wr <= en && rnw;
			if(rnw)
				m0_rsd <= data;
		end
	end
	endtask


	task m0_recv_req;
	input en;
	begin
		@(posedge clk)
		begin
			m0_rqa_rd <= en;
			m0_rqd_rd <= en;
		end
	end
	endtask


	task m1_send_res;
	input en;
	input [1:0] client;
	input [1:0] err;
	input rnw;
	input [63:0] data;
	begin
		@(posedge clk)
		begin
			/*          client  thread  arg   rnw  err */
			m1_rss <= { client, 3'b000, 1'b0, rnw, err };
			m1_rss_wr <= en;
			m1_rsd_wr <= en && rnw;
			if(rnw)
				m1_rsd <= data;
		end
	end
	endtask


	task m1_recv_req;
	input en;
	begin
		@(posedge clk)
		begin
			m1_rqa_rd <= en;
			m1_rqd_rd <= en;
		end
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_mem_hub_simple);

		clk = 1;
		nrst = 0;

		cu_m_sel = 1'b0;
		cu_rqa_wr = 1'b0;
		cu_rss_rd = 1'b0;
		cu_rsd_rd = 1'b0;
		vpu0_rqa_wr = 1'b0;
		vpu0_rqd_wr = 1'b0;
		vpu0_rss_rd = 1'b0;
		vpu0_rsd_rd = 1'b0;
		vpu1_rqa_wr = 1'b0;
		vpu1_rqd_wr = 1'b0;
		vpu1_rss_rd = 1'b0;
		vpu1_rsd_rd = 1'b0;
		m0_rqa_rd = 1'b0;
		m0_rqd_rd = 1'b0;
		m0_rss_wr = 1'b0;
		m0_rsd_wr = 1'b0;
		m1_rqa_rd = 1'b0;
		m1_rqd_rd = 1'b0;
		m1_rss_wr = 1'b0;
		m1_rsd_wr = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/*****************/

		m0_recv_req(1'b1);
		m1_recv_req(1'b1);

		/** Test - CU sends read request through M0 */
		@(posedge clk) test_name <= "  CU_1";

		cu_recv_res(1'b1);
		cu_set_msel(1'b0);

		cu_send_req(1'b1, 36'hFEFEFAFA1);
		cu_send_req(1'b1, 36'hFEFEFAFA2);
		cu_send_req(1'b0, 36'h000000000);

		wait_pos_clk8();

		m0_send_res(1'b1, 2'b00, 2'b00, 1'b1, 64'hDEADBEEFCAFEBE00);
		m0_send_res(1'b1, 2'b00, 2'b00, 1'b1, 64'hDEADBEEFCAFEBE01);
		m0_send_res(1'b0, 2'b00, 2'b00, 1'b1, 64'h0000000000000000);

		wait_pos_clk8();

		/** Test - CU sends read request through M1 */
		@(posedge clk) test_name <= "  CU_2";

		cu_set_msel(1'b1);

		cu_send_req(1'b1, 36'hFEFEFAFB1);
		cu_send_req(1'b1, 36'hFEFEFAFB2);
		cu_send_req(1'b0, 36'h000000000);

		wait_pos_clk8();

		m1_send_res(1'b1, 2'b00, 2'b00, 1'b1, 64'hDEADBEEFCAFEBC00);
		m1_send_res(1'b1, 2'b00, 2'b00, 1'b1, 64'hDEADBEEFCAFEBC01);
		m1_send_res(1'b0, 2'b00, 2'b00, 1'b1, 64'h0000000000000000);

		wait_pos_clk8();

		cu_set_msel(1'b0);
		cu_recv_res(1'b0);

		/** Test - VPU0 sends read request through M0 */
		@(posedge clk) test_name <= "VPU0_1";

		vpu0_recv_res(1'b1);

		vpu0_send_req(1'b1, 37'hBB0AA0, 1'b0, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu0_send_req(1'b1, 37'hBB0AA4, 1'b0, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu0_send_req(1'b0, 37'hBB0AA8, 1'b0, 1'b1, 8'hFF, 64'h0000000000000000);

		wait_pos_clk8();

		m0_send_res(1'b1, 2'b01, 2'b00, 1'b1, 64'hDEADBEEFCAFEBC00);
		m0_send_res(1'b1, 2'b01, 2'b00, 1'b1, 64'hDEADBEEFCAFEBC01);
		m0_send_res(1'b0, 2'b01, 2'b00, 1'b1, 64'h0000000000000000);

		wait_pos_clk8();

		/** Test - VPU0 sends read request through M1 */
		@(posedge clk) test_name <= "VPU0_2";

		vpu0_send_req(1'b1, 37'hBB0AB0, 1'b1, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu0_send_req(1'b1, 37'hBB0AB4, 1'b1, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu0_send_req(1'b0, 37'hBB0AB8, 1'b1, 1'b1, 8'hFF, 64'h0000000000000000);

		wait_pos_clk8();

		m1_send_res(1'b1, 2'b01, 2'b00, 1'b1, 64'hDEADBEEFCAFEBD00);
		m1_send_res(1'b1, 2'b01, 2'b00, 1'b1, 64'hDEADBEEFCAFEBD01);
		m1_send_res(1'b0, 2'b01, 2'b00, 1'b1, 64'h0000000000000000);

		wait_pos_clk8();

		/** Test - VPU0 sends write request (should go through M0) */
		@(posedge clk) test_name <= "VPU0_3";

		vpu0_send_req(1'b1, 37'hBB0AC0, 1'b0, 1'b0, 8'hFF, 64'hDEADBEEFCAFE1100);
		vpu0_send_req(1'b1, 37'hBB0AC4, 1'b0, 1'b0, 8'hFF, 64'hDEADBEEFCAFE1101);
		vpu0_send_req(1'b0, 37'hBB0AC8, 1'b0, 1'b0, 8'hFF, 64'h0000000000000000);

		wait_pos_clk8();

		m0_send_res(1'b1, 2'b01, 2'b00, 1'b0, 64'hDEADBEEFCAFEBE00);
		m0_send_res(1'b1, 2'b01, 2'b00, 1'b0, 64'hDEADBEEFCAFEBE01);
		m0_send_res(1'b0, 2'b01, 2'b00, 1'b0, 64'h0000000000000000);

		wait_pos_clk8();

		vpu0_recv_res(1'b0);

		/** Test - VPU1 sends read request through M0 */
		@(posedge clk) test_name <= "VPU1_1";

		vpu1_recv_res(1'b1);

		vpu1_send_req(1'b1, 37'hBB0AD0, 1'b0, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu1_send_req(1'b1, 37'hBB0AD4, 1'b0, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu1_send_req(1'b0, 37'hBB0AD8, 1'b0, 1'b1, 8'hFF, 64'h0000000000000000);

		wait_pos_clk8();

		m0_send_res(1'b1, 2'b10, 2'b00, 1'b1, 64'hDEADBEEFCAFEBD00);
		m0_send_res(1'b1, 2'b10, 2'b00, 1'b1, 64'hDEADBEEFCAFEBD01);
		m0_send_res(1'b0, 2'b10, 2'b00, 1'b1, 64'h0000000000000000);

		wait_pos_clk8();

		/** Test - VPU1 sends read request through M1 */
		@(posedge clk) test_name <= "VPU1_2";

		vpu1_send_req(1'b1, 37'hBB0AE0, 1'b1, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu1_send_req(1'b1, 37'hBB0AE4, 1'b1, 1'b1, 8'hFF, 64'h0000000000000000);
		vpu1_send_req(1'b0, 37'hBB0AE8, 1'b1, 1'b1, 8'hFF, 64'h0000000000000000);

		wait_pos_clk8();

		m1_send_res(1'b1, 2'b10, 2'b00, 1'b1, 64'hDEADBEEFCAFEBF00);
		m1_send_res(1'b1, 2'b10, 2'b00, 1'b1, 64'hDEADBEEFCAFEBF01);
		m1_send_res(1'b0, 2'b10, 2'b00, 1'b1, 64'h0000000000000000);

		wait_pos_clk8();

		/** Test - VPU1 sends write request (should go through M1) */
		@(posedge clk) test_name <= "VPU1_3";

		vpu1_send_req(1'b1, 37'hBB0AE0, 1'b0, 1'b0, 8'hFF, 64'hDEADBEEFCAFE1200);
		vpu1_send_req(1'b1, 37'hBB0AE4, 1'b0, 1'b0, 8'hFF, 64'hDEADBEEFCAFE1201);
		vpu1_send_req(1'b0, 37'hBB0AE8, 1'b0, 1'b0, 8'hFF, 64'h0000000000000000);

		wait_pos_clk8();

		m1_send_res(1'b1, 2'b10, 2'b00, 1'b0, 64'hDEADBEEFCAFEBA00);
		m1_send_res(1'b1, 2'b10, 2'b00, 1'b0, 64'hDEADBEEFCAFEBA01);
		m1_send_res(1'b0, 2'b10, 2'b00, 1'b0, 64'h0000000000000000);

		wait_pos_clk8();

		vpu1_recv_res(1'b0);


		#500 $finish;
	end


	/* Memory Hub instance */
	vxe_mem_hub mem_hub(
		.clk(clk),
		.nrst(nrst),
		.i_cu_m_sel(cu_m_sel),
		.i_cu_rqa_vld(w_cu_rqa_vld),
		.i_cu_rqa(w_cu_rqa),
		.o_cu_rqa_rd(w_cu_rqa_rd),
		.i_cu_rss_rdy(w_cu_rss_rdy),
		.o_cu_rss(w_cu_rss),
		.o_cu_rss_wr(w_cu_rss_wr),
		.i_cu_rsd_rdy(w_cu_rsd_rdy),
		.o_cu_rsd(w_cu_rsd),
		.o_cu_rsd_wr(w_cu_rsd_wr),
		.i_vpu0_rqa_vld(w_vpu0_rqa_vld),
		.i_vpu0_rqa(w_vpu0_rqa),
		.o_vpu0_rqa_rd(w_vpu0_rqa_rd),
		.i_vpu0_rqd_vld(w_vpu0_rqd_vld),
		.i_vpu0_rqd(w_vpu0_rqd),
		.o_vpu0_rqd_rd(w_vpu0_rqd_rd),
		.i_vpu0_rss_rdy(w_vpu0_rss_rdy),
		.o_vpu0_rss(w_vpu0_rss),
		.o_vpu0_rss_wr(w_vpu0_rss_wr),
		.i_vpu0_rsd_rdy(w_vpu0_rsd_rdy),
		.o_vpu0_rsd(w_vpu0_rsd),
		.o_vpu0_rsd_wr(w_vpu0_rsd_wr),
		.i_vpu1_rqa_vld(w_vpu1_rqa_vld),
		.i_vpu1_rqa(w_vpu1_rqa),
		.o_vpu1_rqa_rd(w_vpu1_rqa_rd),
		.i_vpu1_rqd_vld(w_vpu1_rqd_vld),
		.i_vpu1_rqd(w_vpu1_rqd),
		.o_vpu1_rqd_rd(w_vpu1_rqd_rd),
		.i_vpu1_rss_rdy(w_vpu1_rss_rdy),
		.o_vpu1_rss(w_vpu1_rss),
		.o_vpu1_rss_wr(w_vpu1_rss_wr),
		.i_vpu1_rsd_rdy(w_vpu1_rsd_rdy),
		.o_vpu1_rsd(w_vpu1_rsd),
		.o_vpu1_rsd_wr(w_vpu1_rsd_wr),
		.i_m0_rqa_rdy(w_m0_rqa_rdy),
		.o_m0_rqa(w_m0_rqa),
		.o_m0_rqa_wr(w_m0_rqa_wr),
		.i_m0_rqd_rdy(w_m0_rqd_rdy),
		.o_m0_rqd(w_m0_rqd),
		.o_m0_rqd_wr(w_m0_rqd_wr),
		.i_m0_rss_vld(w_m0_rss_vld),
		.i_m0_rss(w_m0_rss),
		.o_m0_rss_rd(w_m0_rss_rd),
		.i_m0_rsd_vld(w_m0_rsd_vld),
		.i_m0_rsd(w_m0_rsd),
		.o_m0_rsd_rd(w_m0_rsd_rd),
		.i_m1_rqa_rdy(w_m1_rqa_rdy),
		.o_m1_rqa(w_m1_rqa),
		.o_m1_rqa_wr(w_m1_rqa_wr),
		.i_m1_rqd_rdy(w_m1_rqd_rdy),
		.o_m1_rqd(w_m1_rqd),
		.o_m1_rqd_wr(w_m1_rqd_wr),
		.i_m1_rss_vld(w_m1_rss_vld),
		.i_m1_rss(w_m1_rss),
		.o_m1_rss_rd(w_m1_rss_rd),
		.i_m1_rsd_vld(w_m1_rsd_vld),
		.i_m1_rsd(w_m1_rsd),
		.o_m1_rsd_rd(w_m1_rsd_rd)
	);


	/* CU request FIFO (address channel) */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) fifo_cu_rqa (
		.clk(clk),
		.nrst(nrst),
		.data_in(cu_rqa),
		.data_out(w_cu_rqa),
		.rd(w_cu_rqa_rd),
		.wr(cu_rqa_wr),
		.in_rdy(cu_rqa_rdy),
		.out_vld(w_cu_rqa_vld)
	);

	/* CU response FIFO (status channel) */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) fifo_cu_rss (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_cu_rss),
		.data_out(cu_rss),
		.rd(cu_rss_rd),
		.wr(w_cu_rss_wr),
		.in_rdy(w_cu_rss_rdy),
		.out_vld(cu_rss_vld)
	);

	/* CU response FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) fifo_cu_rsd (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_cu_rsd),
		.data_out(cu_rsd),
		.rd(cu_rsd_rd),
		.wr(w_cu_rsd_wr),
		.in_rdy(w_cu_rsd_rdy),
		.out_vld(cu_rsd_vld)
	);


	/* VPU0 request FIFO (address channel) */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) fifo_vpu0_rqa (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu0_rqa),
		.data_out(w_vpu0_rqa),
		.rd(w_vpu0_rqa_rd),
		.wr(vpu0_rqa_wr),
		.in_rdy(vpu0_rqa_rdy),
		.out_vld(w_vpu0_rqa_vld)
	);

	/* VPU0 request FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) fifo_vpu0_rqd (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu0_rqd),
		.data_out(w_vpu0_rqd),
		.rd(w_vpu0_rqd_rd),
		.wr(vpu0_rqd_wr),
		.in_rdy(vpu0_rqd_rdy),
		.out_vld(w_vpu0_rqd_vld)
	);

	/* VPU0 response FIFO (status channel) */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) fifo_vpu0_rss (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_vpu0_rss),
		.data_out(vpu0_rss),
		.rd(vpu0_rss_rd),
		.wr(w_vpu0_rss_wr),
		.in_rdy(w_vpu0_rss_rdy),
		.out_vld(vpu0_rss_vld)
	);

	/* VPU0 response FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) fifo_vpu0_rsd (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_vpu0_rsd),
		.data_out(vpu0_rsd),
		.rd(vpu0_rsd_rd),
		.wr(w_vpu0_rsd_wr),
		.in_rdy(w_vpu0_rsd_rdy),
		.out_vld(vpu0_rsd_vld)
	);


	/* VPU1 request FIFO (address channel) */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) fifo_vpu1_rqa (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu1_rqa),
		.data_out(w_vpu1_rqa),
		.rd(w_vpu1_rqa_rd),
		.wr(vpu1_rqa_wr),
		.in_rdy(vpu1_rqa_rdy),
		.out_vld(w_vpu1_rqa_vld)
	);

	/* VPU1 request FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) fifo_vpu1_rqd (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu1_rqd),
		.data_out(w_vpu1_rqd),
		.rd(w_vpu1_rqd_rd),
		.wr(vpu1_rqd_wr),
		.in_rdy(vpu1_rqd_rdy),
		.out_vld(w_vpu1_rqd_vld)
	);

	/* VPU1 response FIFO (status channel) */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) fifo_vpu1_rss (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_vpu1_rss),
		.data_out(vpu1_rss),
		.rd(vpu1_rss_rd),
		.wr(w_vpu1_rss_wr),
		.in_rdy(w_vpu1_rss_rdy),
		.out_vld(vpu1_rss_vld)
	);

	/* VPU1 response FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) fifo_vpu1_rsd (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_vpu1_rsd),
		.data_out(vpu1_rsd),
		.rd(vpu1_rsd_rd),
		.wr(w_vpu1_rsd_wr),
		.in_rdy(w_vpu1_rsd_rdy),
		.out_vld(vpu1_rsd_vld)
	);


	/* Master 0 request FIFO (address channel) */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) fifo_m0_rqa (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_m0_rqa),
		.data_out(m0_rqa),
		.rd(m0_rqa_rd),
		.wr(w_m0_rqa_wr),
		.in_rdy(w_m0_rqa_rdy),
		.out_vld(m0_rqa_vld)
	);

	/* Master 0 request FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) fifo_m0_rqd (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_m0_rqd),
		.data_out(m0_rqd),
		.rd(m0_rqd_rd),
		.wr(w_m0_rqd_wr),
		.in_rdy(w_m0_rqd_rdy),
		.out_vld(m0_rqd_vld)
	);

	/* Master 0 response FIFO (status channel) */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) fifo_m0_rss (
		.clk(clk),
		.nrst(nrst),
		.data_in(m0_rss),
		.data_out(w_m0_rss),
		.rd(w_m0_rss_rd),
		.wr(m0_rss_wr),
		.in_rdy(m0_rss_rdy),
		.out_vld(w_m0_rss_vld)
	);

	/* Master 0 response FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) fifo_m0_rsd (
		.clk(clk),
		.nrst(nrst),
		.data_in(m0_rsd),
		.data_out(w_m0_rsd),
		.rd(w_m0_rsd_rd),
		.wr(m0_rsd_wr),
		.in_rdy(m0_rsd_rdy),
		.out_vld(w_m0_rsd_vld)
	);


	/* Master 1 request FIFO (address channel) */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) fifo_m1_rqa (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_m1_rqa),
		.data_out(m1_rqa),
		.rd(m1_rqa_rd),
		.wr(w_m1_rqa_wr),
		.in_rdy(w_m1_rqa_rdy),
		.out_vld(m1_rqa_vld)
	);

	/* Master 1 request FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) fifo_m1_rqd (
		.clk(clk),
		.nrst(nrst),
		.data_in(w_m1_rqd),
		.data_out(m1_rqd),
		.rd(m1_rqd_rd),
		.wr(w_m1_rqd_wr),
		.in_rdy(w_m1_rqd_rdy),
		.out_vld(m1_rqd_vld)
	);

	/* Master 1 response FIFO (status channel) */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) fifo_m1_rss (
		.clk(clk),
		.nrst(nrst),
		.data_in(m1_rss),
		.data_out(w_m1_rss),
		.rd(w_m1_rss_rd),
		.wr(m1_rss_wr),
		.in_rdy(m1_rss_rdy),
		.out_vld(w_m1_rss_vld)
	);

	/* Master 1 response FIFO (data channel) */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) fifo_m1_rsd (
		.clk(clk),
		.nrst(nrst),
		.data_in(m1_rsd),
		.data_out(w_m1_rsd),
		.rd(w_m1_rsd_rd),
		.wr(m1_rsd_wr),
		.in_rdy(m1_rsd_rdy),
		.out_vld(w_m1_rsd_vld)
	);


endmodule /* tb_vxe_mem_hub_simple */
