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
 * Testbench for VxE CU upstream traffic control
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_mem_hub_cu_us();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Master select */
	reg		m_sel;
	/* Incoming request */
	wire		rqa_vld;
	wire [43:0]	rqa;
	wire		rqa_rd;
	/* Route to Master 0  */
	wire		m0_rqa_rdy;
	wire [43:0]	m0_rqa;
	wire		m0_rqa_wr;
	/* Route to Master 1  */
	wire		m1_rqa_rdy;
	wire [43:0]	m1_rqa;
	wire		m1_rqa_wr;
	/* Request FIFO signals */
	wire		fifo_rqa_rdy;
	reg [43:0]	fifo_rqa;
	reg		fifo_rqa_wr;
	/* FIFO for outgoing requests from master 0 */
	wire [43:0]	fifo_dest0_rqa;
	reg		fifo_dest0_rd;
	wire		fifo_dest0_vld;
	/* FIFO for outgoing requests from master 1 */
	wire [43:0]	fifo_dest1_rqa;
	reg		fifo_dest1_rd;
	wire		fifo_dest1_vld;
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
		$dumpvars(0, tb_vxe_mem_hub_cu_us);

		clk = 1;
		nrst = 0;

		m_sel = 1'b0;
		fifo_rqa = 44'b0;
		fifo_rqa_wr = 1'b0;

		fifo_dest0_rd = 1'b0;
		fifo_dest1_rd = 1'b0;

		gen_traffic = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/* Generate traffic for master port 0 */
		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_dest0_rd <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) gen_traffic <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_dest0_rd <= 1'b0;


		/* Generate traffic for master port 1 */
		@(posedge clk) m_sel <= 1'b1;
		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_dest1_rd <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) gen_traffic <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) fifo_dest1_rd <= 1'b0;


		#500 $finish;
	end


	/* Client upstream */
	vxe_mem_hub_cu_us cu_us(
		.clk(clk),
		.nrst(nrst),
		.i_m_sel(m_sel),
		.i_rqa_vld(rqa_vld),
		.i_rqa(rqa),
		.o_rqa_rd(rqa_rd),
		.i_m0_rqa_rdy(m0_rqa_rdy),
		.o_m0_rqa(m0_rqa),
		.o_m0_rqa_wr(m0_rqa_wr),
		.i_m1_rqa_rdy(m1_rqa_rdy),
		.o_m1_rqa(m1_rqa),
		.o_m1_rqa_wr(m1_rqa_wr)
	);


	/* Input requests FIFO */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) reqf (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqa),
		.data_out(rqa),
		.rd(rqa_rd),
		.wr(fifo_rqa_wr),
		.in_rdy(fifo_rqa_rdy),
		.out_vld(rqa_vld)
	);


	/* FIFO for outgoing requests routed to master port 0 */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) m0f (
		.clk(clk),
		.nrst(nrst),
		.data_in(m0_rqa),
		.data_out(fifo_dest0_rqa),
		.rd(fifo_dest0_rd),
		.wr(m0_rqa_wr),
		.in_rdy(m0_rqa_rdy),
		.out_vld(fifo_dest0_vld)
	);


	/* FIFO for outgoing requests routed to master port 1 */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) m1f (
		.clk(clk),
		.nrst(nrst),
		.data_in(m1_rqa),
		.data_out(fifo_dest1_rqa),
		.rd(fifo_dest1_rd),
		.wr(m1_rqa_wr),
		.in_rdy(m1_rqa_rdy),
		.out_vld(fifo_dest1_vld)
	);


	/* Simple traffic generation */
	reg [36:0] pl_q;
	reg send_q;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			pl_q <= 37'h0;
			send_q <= 1'b0;
		end
		else if(gen_traffic)
		begin
			if(!send_q)
			begin
				fifo_rqa <= { 6'b111100, 1'b1, pl_q };
				fifo_rqa_wr <= 1'b1;
				pl_q <= pl_q + 1'b1;
				send_q <= 1'b1;
			end
			else if(fifo_rqa_rdy)
			begin
				fifo_rqa <= { 6'b111100, 1'b1, pl_q };
				pl_q <= pl_q + 1'b1;
			end
		end
		else
		begin
			pl_q <= 37'hbeef00000;
			send_q <= 1'b0;
			fifo_rqa_wr <= 1'b0;
		end
	end


endmodule /* tb_vxe_mem_hub_cu_us */
