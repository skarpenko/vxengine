/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * Testbench for VxE CU fetch unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_cu_fetch_unit();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;

	/* Memory request signals */
	wire		rqa_vld;
	wire [43:0]	rqa;
	reg		rqa_rd;
	wire		fifo_rqa_rdy;
	wire [43:0]	fifo_rqa;
	wire		fifo_rqa_wr;
	/* Memory response signals */
	wire		rss_rdy;
	reg [8:0]	rss;
	reg		rss_wr;
	wire		fifo_rss_vld;
	wire [8:0]	fifo_rss;
	wire		fifo_rss_rd;
	wire		rsd_rdy;
	reg [63:0]	rsd;
	reg		rsd_wr;
	wire		fifo_rsd_vld;
	wire [63:0]	fifo_rsd;
	wire		fifo_rsd_rd;
	/* Control signals */
	reg		start;
	reg [36:0]	start_addr;
	reg		stop_drain;
	wire		busy;
	wire [36:0]	fetch_addr;
	wire [63:0]	fetch_data;
	wire		fetch_vld;
	wire		fetch_err;
	reg		fetch_rd;

	/* Misc signals */
	reg [0:55]	test_name;
	reg		gen_traffic;
	reg [8:0]	gen_rss;
	reg [63:0]	gen_rsd;


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


	task wait_pos_clk16;
	begin
		wait_pos_clk8();
		wait_pos_clk8();
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_cu_fetch_unit);

		clk = 1;
		nrst = 0;

		start = 0;
		start_addr = 0;
		stop_drain = 0;
		fetch_rd = 0;

		gen_traffic = 0;
		gen_rss = 0;
		gen_rsd = 0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/**********************************************/

		/* Test 1 - requests path congestion
		 *   1. Disable requests acceptance by memory subsystem.
		 *   2. Start sending command fetch requests.
		 *   3. Enable requests acceptance by memory subsystem.
		 *   4. Stop and drain.
		 */
		@(posedge clk)
		begin
			test_name <= "Test 1 ";
			start_addr <= 37'h1;	/* Set fetch address */
			gen_traffic <= 1'b0;	/* Do not generate responses */
			gen_rss <= 9'h3;
			gen_rsd <= 64'hfefefafa00000001;
		end
		@(posedge clk)
		begin
			start <= 1'b1;		/* Start fetch */
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			gen_traffic <= 1'b1;	/* Generate responses */
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			stop_drain <= 1'b1;	/* Stop and drain */
		end
		@(posedge clk)
		begin
			stop_drain <= 1'b0;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			gen_traffic <= 1'b0;
		end

		wait_pos_clk16();


		/* Test 2 - normal request and response operation */
		@(posedge clk)
		begin
			test_name <= "Test 2 ";
			start_addr <= 37'h1;	/* Set fetch address */
			gen_rss <= 9'h3;
			gen_rsd <= 64'hfefefafa00000001;
		end
		@(posedge clk)
		begin
			start <= 1'b1;		/* Start fetch */
			gen_traffic <= 1'b1;
			fetch_rd <= 1'b1;
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk16();

		@(posedge clk)
		begin
			stop_drain <= 1'b1;	/* Stop and drain */
			fetch_rd <= 1'b0;
		end
		@(posedge clk)
		begin
			stop_drain <= 1'b0;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			gen_traffic <= 1'b0;
		end

		wait_pos_clk16();


		/* Test 3 - normal request and response operation (second) */
		@(posedge clk)
		begin
			test_name <= "Test 3 ";
			start_addr <= 37'h1;	/* Set fetch address */
			gen_rss <= 9'h0;	/* No error responses */
			gen_rsd <= 64'hfefefafa00000001;
		end
		@(posedge clk)
		begin
			start <= 1'b1;		/* Start fetch */
			gen_traffic <= 1'b1;
			fetch_rd <= 1'b1;
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk16();

		@(posedge clk)
		begin
			stop_drain <= 1'b1;	/* Stop and drain */
			fetch_rd <= 1'b0;
		end
		@(posedge clk)
		begin
			stop_drain <= 1'b0;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			gen_traffic <= 1'b0;
		end

		wait_pos_clk16();


		/* Test 4 - congestion on client side */
		@(posedge clk)
		begin
			test_name <= "Test 4 ";
			start_addr <= 37'h1;	/* Set fetch address */
			gen_rss <= 9'h0;	/* No error responses */
			gen_rsd <= 64'hfefefafa00000001;
		end
		@(posedge clk)
		begin
			start <= 1'b1;		/* Start fetch */
			gen_traffic <= 1'b1;
			fetch_rd <= 1'b0;	/* Do not read fetched data */
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk16();

		@(posedge clk)
		begin
			fetch_rd <= 1'b1;	/* Start reading fetched data */
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			stop_drain <= 1'b1;	/* Stop and drain */
			fetch_rd <= 1'b0;
		end
		@(posedge clk)
		begin
			stop_drain <= 1'b0;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			gen_traffic <= 1'b0;
		end

		wait_pos_clk16();



		#500 $finish;
	end


	/* Fetch unit instance */
	vxe_cu_fetch_unit #(
		.CLIENT_ID(0),
		.FETCH_DEPTH_POW2(4)
	) fetch_unit (
		.clk(clk),
		.nrst(nrst),
		.i_rqa_rdy(fifo_rqa_rdy),
		.o_rqa(fifo_rqa),
		.o_rqa_wr(fifo_rqa_wr),
		.i_rss_vld(fifo_rss_vld),
		.i_rss(fifo_rss),
		.o_rss_rd(fifo_rss_rd),
		.i_rsd_vld(fifo_rsd_vld),
		.i_rsd(fifo_rsd),
		.o_rsd_rd(fifo_rsd_rd),
		.i_start(start),
		.i_start_addr(start_addr),
		.i_stop_drain(stop_drain),
		.o_busy(busy),
		.o_fetch_addr(fetch_addr),
		.o_fetch_data(fetch_data),
		.o_fetch_vld(fetch_vld),
		.o_fetch_err(fetch_err),
		.i_fetch_rd(fetch_rd)
	);

	/* FIFO for outgoing requests */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) req (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqa),
		.data_out(rqa),
		.rd(rqa_rd),
		.wr(fifo_rqa_wr),
		.in_rdy(fifo_rqa_rdy),
		.out_vld(rqa_vld)
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


	/** Simple traffic generation **/

	/* Requests tracking */
	reg [2:0]	rq_rp;	/* Read pointer */
	reg [2:0]	rq_wp;	/* Write pointer */
	/* Previous read pointer */
	wire [2:0]	rq_pre_rp = rq_rp - 1'b1;
	/* Requests buffer states */
	wire rq_empty = (rq_rp[1:0] == rq_wp[1:0]) &&
		(rq_rp[2] == rq_wp[2]);
	wire rq_full = (rq_rp[1:0] == rq_wp[1:0]) &&
		(rq_rp[2] != rq_wp[2]);
	wire rq_pre_full = (rq_pre_rp[1:0] == rq_wp[1:0]) &&
		(rq_pre_rp[2] != rq_wp[2]);

	/* Requests buffer stall condition */
	wire rq_stall = rq_full || rq_pre_full;

	/* Requests receiving FSM states */
	localparam [1:0]	FSM_RQ_IDLE = 2'b00;
	localparam [1:0]	FSM_RQ_RECV = 2'b01;
	localparam [1:0]	FSM_RQ_STLL = 2'b10;


	/* Requests receiving FSM */
	reg [1:0] rq_fsm;

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			rqa_rd <= 1'b0;
			rq_wp <= 3'b000;
			rq_fsm <= FSM_RQ_IDLE;
		end
		else if(rq_fsm == FSM_RQ_RECV)
		begin
			if(rqa_vld)
			begin
				rq_wp <= rq_wp + 1'b1;
			end

			if(rq_stall)
			begin
				rqa_rd <= 1'b0;
				rq_fsm <= FSM_RQ_STLL;
			end
		end
		else if(rq_fsm == FSM_RQ_STLL)
		begin
			if(!rq_stall)
			begin
				rqa_rd <= 1'b1;
				rq_fsm <= FSM_RQ_RECV;
			end
		end
		else	/* FSM_RQ_IDLE */
		begin
			if(gen_traffic)
			begin
				rqa_rd <= 1'b1;
				rq_fsm <= FSM_RQ_RECV;
			end
		end
	end


	/* Response traffic */
	reg [8:0] s_pl_q;
	reg [63:0] d_pl_q;
	reg s_send_q;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			s_pl_q <= 9'h0;
			d_pl_q <= 64'h0;
			s_send_q <= 1'b0;
			rq_rp <= 3'b000;
			rss_wr <= 1'b0;
			rsd_wr <= 1'b0;
		end
		else if(gen_traffic)
		begin
			if(!s_send_q && !rq_empty)
			begin
				rss <= s_pl_q;
				rsd <= d_pl_q;
				rss_wr <= 1'b1;
				rsd_wr <= 1'b1;
				/* s_pl_q <= s_pl_q + 1'b1; */
				d_pl_q <= d_pl_q + 1'b1;
				rq_rp <= rq_rp + 1'b1;
				s_send_q <= 1'b1;
			end
			else if(rss_rdy && s_send_q && !rq_empty)
			begin
				rss <= s_pl_q;
				rsd <= d_pl_q;
				rq_rp <= rq_rp + 1'b1;
				/* s_pl_q <= s_pl_q + 1'b1; */
				d_pl_q <= d_pl_q + 1'b1;
			end
			else if(rss_rdy && s_send_q && rq_empty)
			begin
				s_send_q <= 1'b0;
				rss_wr <= 1'b0;
				rsd_wr <= 1'b0;
			end
		end
		else
		begin
			s_pl_q <= gen_rss;
			d_pl_q <= gen_rsd;
			s_send_q <= 1'b0;
			rss_wr <= 1'b0;
			rsd_wr <= 1'b0;
		end
	end


endmodule /* tb_vxe_cu_fetch_unit */
