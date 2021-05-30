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
 * Testbench for VxE CU downstream traffic control
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_mem_hub_cu_ds();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Master select */
	reg		m_sel;
	/* Incoming response status */
	wire [8:0]	rss;
	wire		rss_wr;
	wire		rss_rdy;
	wire [8:0]	fifo_rss;
	reg		fifo_rss_rd;
	wire		fifo_rss_vld;
	/* Incoming response data */
	wire [63:0]	rsd;
	wire		rsd_wr;
	wire		rsd_rdy;
	wire [63:0]	fifo_rsd;
	reg		fifo_rsd_rd;
	wire		fifo_rsd_vld;
	/* Incoming response status from master 0 */
	wire [8:0]	m0_rss;
	wire		m0_rss_rd;
	wire		m0_rss_vld;
	wire [8:0]	fifo_m0_rss;
	wire		fifo_m0_rss_wr;
	wire		fifo_m0_rss_rdy;
	/* Incoming response data from master 0 */
	wire [63:0]	m0_rsd;
	wire		m0_rsd_rd;
	wire		m0_rsd_vld;
	wire [63:0]	fifo_m0_rsd;
	wire		fifo_m0_rsd_wr;
	wire		fifo_m0_rsd_rdy;
	/* Incoming response status from master 1 */
	wire [8:0]	m1_rss;
	wire		m1_rss_rd;
	wire		m1_rss_vld;
	wire [8:0]	fifo_m1_rss;
	wire		fifo_m1_rss_wr;
	wire		fifo_m1_rss_rdy;
	/* Incoming response data from master 1 */
	wire [63:0]	m1_rsd;
	wire		m1_rsd_rd;
	wire		m1_rsd_vld;
	wire [63:0]	fifo_m1_rsd;
	wire		fifo_m1_rsd_wr;
	wire		fifo_m1_rsd_rdy;
	/* Traffic generator on/off control */
	reg		gen_traffic;


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


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_mem_hub_cu_ds);

		clk = 1;
		nrst = 0;

		m_sel = 1'b0;

		fifo_rss_rd = 1'b0;
		fifo_rsd_rd = 1'b0;

		gen_traffic = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/* Generate response traffic from master port 0 */
		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_rss_rd <= 1'b1;
		@(posedge clk) fifo_rsd_rd <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) gen_traffic <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_rss_rd <= 1'b0;
		@(posedge clk) fifo_rsd_rd <= 1'b0;


		/* Generate response traffic from master port 1 */
		@(posedge clk) m_sel <= 1'b1;
		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_rss_rd <= 1'b1;
		@(posedge clk) fifo_rsd_rd <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) gen_traffic <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_rss_rd <= 1'b0;
		@(posedge clk) fifo_rsd_rd <= 1'b0;


		#500 $finish;
	end


	/* Client downstream */
	vxe_mem_hub_cu_ds cu_ds(
		.clk(clk),
		.nrst(nrst),
		.i_m_sel(m_sel),
		.i_rss_rdy(rss_rdy),
		.o_rss(rss),
		.o_rss_wr(rss_wr),
		.i_rsd_rdy(rsd_rdy),
		.o_rsd(rsd),
		.o_rsd_wr(rsd_wr),
		.i_m0_rss_vld(m0_rss_vld),
		.i_m0_rss(m0_rss),
		.o_m0_rss_rd(m0_rss_rd),
		.i_m0_rsd_vld(m0_rsd_vld),
		.i_m0_rsd(m0_rsd),
		.o_m0_rsd_rd(m0_rsd_rd),
		.i_m1_rss_vld(m1_rss_vld),
		.i_m1_rss(m1_rss),
		.o_m1_rss_rd(m1_rss_rd),
		.i_m1_rsd_vld(m1_rsd_vld),
		.i_m1_rsd(m1_rsd),
		.o_m1_rsd_rd(m1_rsd_rd)
	);


	/* FIFO for incoming response status */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) resp_s (
		.clk(clk),
		.nrst(nrst),
		.data_in(rss),
		.data_out(fifo_rss),
		.rd(fifo_rss_rd),
		.wr(rss_wr),
		.in_rdy(rss_rdy),
		.out_vld(fifo_rss_vld)
	);


	/* FIFO for incoming response data */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resp_d (
		.clk(clk),
		.nrst(nrst),
		.data_in(rsd),
		.data_out(fifo_rsd),
		.rd(fifo_rsd_rd),
		.wr(rsd_wr),
		.in_rdy(rsd_rdy),
		.out_vld(fifo_rsd_vld)
	);


	/* FIFO for response status from master port 0 */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) m0_resp_s (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_m0_rss),
		.data_out(m0_rss),
		.rd(m0_rss_rd),
		.wr(fifo_m0_rss_wr),
		.in_rdy(fifo_m0_rss_rdy),
		.out_vld(m0_rss_vld)
	);


	/* FIFO for response data from master port 0 */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) m0_resp_d (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_m0_rsd),
		.data_out(m0_rsd),
		.rd(m0_rsd_rd),
		.wr(fifo_m0_rsd_wr),
		.in_rdy(fifo_m0_rsd_rdy),
		.out_vld(m0_rsd_vld)
	);


	/* FIFO for response status from master port 1 */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) m1_resp_s (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_m1_rss),
		.data_out(m1_rss),
		.rd(m1_rss_rd),
		.wr(fifo_m1_rss_wr),
		.in_rdy(fifo_m1_rss_rdy),
		.out_vld(m1_rss_vld)
	);


	/* FIFO for response data from master port 1 */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) m1_resp_d (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_m1_rsd),
		.data_out(m1_rsd),
		.rd(m1_rsd_rd),
		.wr(fifo_m1_rsd_wr),
		.in_rdy(fifo_m1_rsd_rdy),
		.out_vld(m1_rsd_vld)
	);


	/** Simple traffic generation **/

	reg [8:0]	g_rss;
	reg		g_rss_wr;
	wire		g_rss_rdy;

	reg [63:0]	g_rsd;
	reg		g_rsd_wr;
	wire		g_rsd_rdy;

	assign fifo_m0_rss	= (m_sel == 1'b0) ? g_rss : 9'b0;
	assign fifo_m0_rss_wr	= (m_sel == 1'b0) ? g_rss_wr : 1'b0;
	assign fifo_m1_rss	= (m_sel == 1'b1) ? g_rss : 9'b0;
	assign fifo_m1_rss_wr	= (m_sel == 1'b1) ? g_rss_wr : 1'b0;
	assign g_rss_rdy	= (m_sel == 1'b0) ? fifo_m0_rss_rdy : fifo_m1_rss_rdy;

	assign fifo_m0_rsd	= (m_sel == 1'b0) ? g_rsd : 64'b0;
	assign fifo_m0_rsd_wr	= (m_sel == 1'b0) ? g_rsd_wr : 1'b0;
	assign fifo_m1_rsd	= (m_sel == 1'b1) ? g_rsd : 64'b0;
	assign fifo_m1_rsd_wr	= (m_sel == 1'b1) ? g_rsd_wr : 1'b0;
	assign g_rsd_rdy	= (m_sel == 1'b0) ? fifo_m0_rsd_rdy : fifo_m1_rsd_rdy;


	/* Response status traffic */
	reg [8:0] s_pl_q;
	reg s_send_q;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			s_pl_q <= 9'h0;
			s_send_q <= 1'b0;
		end
		else if(gen_traffic)
		begin
			if(!s_send_q)
			begin
				g_rss <= s_pl_q;
				g_rss_wr <= 1'b1;
				s_pl_q <= s_pl_q + 1'b1;
				s_send_q <= 1'b1;
			end
			else if(g_rss_rdy)
			begin
				g_rss <= s_pl_q;
				s_pl_q <= s_pl_q + 1'b1;
			end
		end
		else
		begin
			s_pl_q <= 9'h100;
			s_send_q <= 1'b0;
			g_rss_wr <= 1'b0;
		end
	end


	/* Response data traffic */
	reg [63:0] d_pl_q;
	reg d_send_q;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			d_pl_q <= 64'h0;
			d_send_q <= 1'b0;
		end
		else if(gen_traffic)
		begin
			if(!d_send_q)
			begin
				g_rsd <= d_pl_q;
				g_rsd_wr <= 1'b1;
				d_pl_q <= d_pl_q + 1'b1;
				d_send_q <= 1'b1;
			end
			else if(g_rsd_rdy)
			begin
				g_rsd <= d_pl_q;
				d_pl_q <= d_pl_q + 1'b1;
			end
		end
		else
		begin
			d_pl_q <= 64'hFE00_0000_0000_0000;
			d_send_q <= 1'b0;
			g_rsd_wr <= 1'b0;
		end
	end


endmodule /* tb_vxe_mem_hub_cu_ds */
