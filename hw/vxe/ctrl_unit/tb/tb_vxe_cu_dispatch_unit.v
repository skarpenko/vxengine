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
 * Testbench for VxE CU dispatch unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_cu_dispatch_unit();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam MEMSZ = 256;		/* Command memory size */
	localparam MEMIW = 8;		/* Memory index width (bits) */

	reg		clk;
	reg		nrst;

	/* Fetch unit memory request signals */
	wire		rqa_vld;
	wire [43:0]	rqa;
	reg		rqa_rd;
	wire		fifo_rqa_rdy;
	wire [43:0]	fifo_rqa;
	wire		fifo_rqa_wr;
	/* Fetch unit memory response signals */
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
	/* Fetch unit control signals */
	reg		fetch_start;
	reg [36:0]	fetch_start_addr;
	reg		fetch_stop_drain;
	wire		fetch_busy;
	wire [36:0]	fetch_addr;
	wire [63:0]	fetch_data;
	wire		fetch_vld;
	wire		fetch_err;
	wire		fetch_rd;
	/* Dispatch unit faults */
	wire		flt_fetch;
	wire [36:0]	flt_fetch_addr;
	wire		flt_decode;
	wire [36:0]	flt_decode_addr;
	wire [63:0]	flt_decode_data;
	/* Dispatch unit control interface */
	wire		ctl_nop;
	wire		ctl_sync;
	wire		ctl_sync_stop;
	wire		ctl_sync_intr;
	reg		ctl_halt;
	reg		ctl_unhalt;
	wire		ctl_pipes_active;
	/* Dispatch unit VPU0 forwarding interface */
	reg		fwd_vpu0_rdy;
	wire [4:0]	fwd_vpu0_op;
	wire [2:0]	fwd_vpu0_th;
	wire [47:0]	fwd_vpu0_pl;
	wire		fwd_vpu0_wr;
	/* Dispatch unit VPU1 forwarding interface */
	reg		fwd_vpu1_rdy;
	wire [4:0]	fwd_vpu1_op;
	wire [2:0]	fwd_vpu1_th;
	wire [47:0]	fwd_vpu1_pl;
	wire		fwd_vpu1_wr;

	/* Misc signals */
	reg [0:55]	test_name;
	reg		test_done;
	reg		srst;

	/* Command memory and responses for traffic generator */
	reg [63:0]	cmdmem[0:MEMSZ-1];
	reg [8:0]	cmdrss[0:MEMSZ-1];


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


	task wait_pos_clk32;
	begin
		wait_pos_clk16();
		wait_pos_clk16();
	end
	endtask


	task wait_pos_clk64;
	begin
		wait_pos_clk32();
		wait_pos_clk32();
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_cu_dispatch_unit);

		clk = 1;
		nrst = 0;

		fetch_start = 0;
		fetch_start_addr = 0;
		fwd_vpu0_rdy = 1;
		fwd_vpu1_rdy = 1;
		ctl_halt = 0;

		srst = 0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/**********************************************/


		/* Test 1 - NOP unhalt */
		$readmemh("hex/dispatchu_t1_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t1_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 1 ";
			fetch_start_addr <= 37'h1;	/* Set fetch address */
		end
		@(posedge clk) fetch_start <= 1'b1;	/* Start fetch */
		@(posedge clk) fetch_start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic and ctl logic */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 2 - Fetch error */
		$readmemh("hex/dispatchu_t2_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t2_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 2 ";
			fetch_start_addr <= 37'h1;	/* Set fetch address */
		end
		@(posedge clk) fetch_start <= 1'b1;	/* Start fetch */
		@(posedge clk) fetch_start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic and ctl logic */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 3 - Decode error */
		$readmemh("hex/dispatchu_t3_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t3_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 3 ";
			fetch_start_addr <= 37'h1;	/* Set fetch address */
		end
		@(posedge clk) fetch_start <= 1'b1;	/* Start fetch */
		@(posedge clk) fetch_start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic and ctl logic */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 4 - Decode and fetch error */
		$readmemh("hex/dispatchu_t4_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t4_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 4 ";
			fetch_start_addr <= 37'h1;	/* Set fetch address */
		end
		@(posedge clk) fetch_start <= 1'b1;	/* Start fetch */
		@(posedge clk) fetch_start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic and ctl logic */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 5 - Simple commands flow */
		$readmemh("hex/dispatchu_t5_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t5_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 5 ";
			fetch_start_addr <= 37'h1;	/* Set fetch address */
		end
		@(posedge clk) fetch_start <= 1'b1;	/* Start fetch */
		@(posedge clk) fetch_start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic and ctl logic */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 6 - Unicast commands flow */
		$readmemh("hex/dispatchu_t6_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t6_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 6 ";
			fetch_start_addr <= 37'h1;	/* Set fetch address */
		end
		@(posedge clk) fetch_start <= 1'b1;	/* Start fetch */
		@(posedge clk) fetch_start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic and ctl logic */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 7 - Halt switch test */
		$readmemh("hex/dispatchu_t6_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t6_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 7 ";
			fetch_start_addr <= 37'h1;	/* Set fetch address */
		end
		@(posedge clk) fetch_start <= 1'b1;	/* Start fetch */
		@(posedge clk) fetch_start <= 1'b0;

		wait_pos_clk64();
		@(posedge clk) ctl_halt <= 1'b1;	/* Trigger halt */
		@(posedge clk) ctl_halt <= 1'b0;
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic and ctl logic */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		#500 $finish;
	end


	/* Dispatch unit instance */
	vxe_cu_dispatch_unit dispatch_unit(
		.clk(clk),
		.nrst(nrst),
		.i_fetch_addr(fetch_addr),
		.i_fetch_data(fetch_data),
		.i_fetch_vld(fetch_vld),
		.i_fetch_err(fetch_err),
		.o_fetch_rd(fetch_rd),
		.o_flt_fetch(flt_fetch),
		.o_flt_fetch_addr(flt_fetch_addr),
		.o_flt_decode(flt_decode),
		.o_flt_decode_addr(flt_decode_addr),
		.o_flt_decode_data(flt_decode_data),
		.o_ctl_nop(ctl_nop),
		.o_ctl_sync(ctl_sync),
		.o_ctl_sync_stop(ctl_sync_stop),
		.o_ctl_sync_intr(ctl_sync_intr),
		.o_ctl_pipes_active(ctl_pipes_active),
		.i_ctl_halt(ctl_halt),
		.i_ctl_unhalt(ctl_unhalt),
		.i_fwd_vpu0_rdy(fwd_vpu0_rdy),
		.o_fwd_vpu0_op(fwd_vpu0_op),
		.o_fwd_vpu0_th(fwd_vpu0_th),
		.o_fwd_vpu0_pl(fwd_vpu0_pl),
		.o_fwd_vpu0_wr(fwd_vpu0_wr),
		.i_fwd_vpu1_rdy(fwd_vpu1_rdy),
		.o_fwd_vpu1_op(fwd_vpu1_op),
		.o_fwd_vpu1_th(fwd_vpu1_th),
		.o_fwd_vpu1_pl(fwd_vpu1_pl),
		.o_fwd_vpu1_wr(fwd_vpu1_wr)
	);


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
		.i_start(fetch_start),
		.i_start_addr(fetch_start_addr),
		.i_stop_drain(fetch_stop_drain),
		.o_busy(fetch_busy),
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
		if(!nrst || srst)
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
			rqa_rd <= 1'b1;
			rq_fsm <= FSM_RQ_RECV;
		end
	end


	/* Response traffic */
	localparam [63:0]	TTERM = 64'hffff_ffff_ffff_ffff;
	reg [MEMIW-1:0] mem_idx;
	reg s_send_q;

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst || srst)
		begin
			mem_idx <= {MEMIW{1'b0}};
			s_send_q <= 1'b0;
			rq_rp <= 3'b000;
			rss_wr <= 1'b0;
			rsd_wr <= 1'b0;
		end
		else
		begin
			if(!s_send_q && !rq_empty)
			begin
				if(cmdmem[mem_idx] != TTERM)
				begin
					rss <= cmdrss[mem_idx];
					rsd <= cmdmem[mem_idx];
					mem_idx <= mem_idx + 1'b1;
				end
				else
				begin
					rss <= 9'h0;
					rsd <= 64'h0;
				end
				rss_wr <= 1'b1;
				rsd_wr <= 1'b1;
				rq_rp <= rq_rp + 1'b1;
				s_send_q <= 1'b1;
			end
			else if(rss_rdy && s_send_q && !rq_empty)
			begin
				if(cmdmem[mem_idx] != TTERM)
				begin
					rss <= cmdrss[mem_idx];
					rsd <= cmdmem[mem_idx];
					mem_idx <= mem_idx + 1'b1;
				end
				else
				begin
					rss <= 9'h0;
					rsd <= 64'h0;
				end
				rq_rp <= rq_rp + 1'b1;
			end
			else if(rss_rdy && s_send_q && rq_empty)
			begin
				s_send_q <= 1'b0;
				rss_wr <= 1'b0;
				rsd_wr <= 1'b0;
			end
		end
	end


	/** Simple control logic **/

	/* Control FSM state */
	localparam [1:0]	FSM_CTL_IDLE = 2'b00;
	localparam [1:0]	FSM_CTL_WAIT = 2'b01;
	localparam [1:0]	FSM_CTL_ACK = 2'b11;

	/* Control FSM state */
	reg [1:0] ctl_fsm;

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst || srst)
		begin
			ctl_fsm <= FSM_CTL_IDLE;
			fetch_stop_drain <= 1'b0;
			ctl_unhalt <= 1'b0;
			test_done <= 1'b0;
		end
		else if(ctl_fsm == FSM_CTL_WAIT)
		begin
			fetch_stop_drain <= 1'b0;

			if(!ctl_pipes_active)
			begin
				ctl_unhalt <= 1'b1;
				test_done <= 1'b1;
				ctl_fsm <= FSM_CTL_ACK;
			end
		end
		else if(ctl_fsm == FSM_CTL_ACK)
		begin
			ctl_unhalt <= 1'b0;

			if(test_done)
			begin
				test_done <= 1'b0;
			end

			ctl_fsm <= FSM_CTL_IDLE;
		end
		else /* FSM_CTL_IDLE */
		begin
			if((ctl_sync && ctl_sync_stop) || ctl_halt || flt_fetch
				|| flt_decode)
			begin
				fetch_stop_drain <= 1'b1;
				ctl_fsm <= FSM_CTL_WAIT;
			end
			else if(ctl_nop || ctl_sync)
			begin
				ctl_unhalt <= 1'b1;
				ctl_fsm <= FSM_CTL_ACK;
			end
		end
	end


endmodule /* tb_vxe_cu_dispatch_unit */
