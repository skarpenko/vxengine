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
 * Testbench for VxE control unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_ctrl_unit();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam MEMSZ = 256;		/* Command memory size */
	localparam MEMIW = 8;		/* Memory index width (bits) */

	reg		clk;
	reg		nrst;

	/* Memory request channel */
	wire		rqa_vld;
	wire [43:0]	rqa;
	reg		rqa_rd;
	wire		fifo_rqa_rdy;
	wire [43:0]	fifo_rqa;
	wire		fifo_rqa_wr;
	/* Memory response channel */
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
	wire		busy;
	reg [36:0]	pgm_addr;
	/* Interrupts and faults state */
	wire		intr_vld;
	wire [3:0]	intr;
	wire [36:0]	last_instr_addr;
	wire [63:0]	last_instr_data;
	wire [1:0]	vpu_fault;
	/* VPU0 interface */
	reg		vpu0_busy;
	reg		vpu0_err;
	wire		vpu0_cmd_sel;
	reg		vpu0_cmd_ack;
	wire [4:0]	vpu0_cmd_op;
	wire [2:0]	vpu0_cmd_th;
	wire [47:0]	vpu0_cmd_pl;
	/* VPU1 interface */
	reg		vpu1_busy;
	reg		vpu1_err;
	wire		vpu1_cmd_sel;
	reg		vpu1_cmd_ack;
	wire [4:0]	vpu1_cmd_op;
	wire [2:0]	vpu1_cmd_th;
	wire [47:0]	vpu1_cmd_pl;

	/* Misc signals */
	reg [0:55]	test_name;
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
		$dumpvars(0, tb_vxe_ctrl_unit);

		clk = 1;
		nrst = 0;

		start = 0;
		pgm_addr = 0;
		vpu0_busy = 0;
		vpu0_err = 0;
		vpu0_cmd_ack = 0;
		vpu1_busy = 0;
		vpu1_err = 0;
		vpu1_cmd_ack = 0;

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
			pgm_addr <= 37'h100;	/* Program address */
			vpu0_cmd_ack <= 1'b1;	/* VPU0 ack */
			vpu1_cmd_ack <= 1'b1;	/* VPU1 ack */
		end
		@(posedge clk) start <= 1'b1;	/* Start */
		@(posedge clk) start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic generator */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 2 - Fetch fault */
		$readmemh("hex/dispatchu_t2_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t2_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 2 ";
			pgm_addr <= 37'h200;	/* Program address */
			vpu0_cmd_ack <= 1'b1;	/* VPU0 ack */
			vpu1_cmd_ack <= 1'b1;	/* VPU1 ack */
		end
		@(posedge clk) start <= 1'b1;	/* Start */
		@(posedge clk) start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic generator */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 3 - Decode fault */
		$readmemh("hex/dispatchu_t3_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t3_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 3 ";
			pgm_addr <= 37'h300;	/* Program address */
			vpu0_cmd_ack <= 1'b1;	/* VPU0 ack */
			vpu1_cmd_ack <= 1'b1;	/* VPU1 ack */
		end
		@(posedge clk) start <= 1'b1;	/* Start */
		@(posedge clk) start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic generator */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 4 - Decode and fetch fault */
		$readmemh("hex/dispatchu_t4_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t4_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 4 ";
			pgm_addr <= 37'h400;	/* Program address */
			vpu0_cmd_ack <= 1'b1;	/* VPU0 ack */
			vpu1_cmd_ack <= 1'b1;	/* VPU1 ack */
		end
		@(posedge clk) start <= 1'b1;	/* Start */
		@(posedge clk) start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic generator */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 5 - Broadcast commands flow */
		$readmemh("hex/dispatchu_t5_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t5_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 5 ";
			pgm_addr <= 37'h500;	/* Program address */
			vpu0_cmd_ack <= 1'b1;	/* VPU0 ack */
			vpu1_cmd_ack <= 1'b1;	/* VPU1 ack */
		end
		@(posedge clk) start <= 1'b1;	/* Start */
		@(posedge clk) start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic generator */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		/* Test 6 - Unicast commands flow */
		$readmemh("hex/dispatchu_t6_cmd.hex", cmdmem);
		$readmemh("hex/dispatchu_t6_rss.hex", cmdrss);

		@(posedge clk)
		begin
			test_name <= "Test 6 ";
			pgm_addr <= 37'h600;	/* Program address */
			vpu0_cmd_ack <= 1'b1;	/* VPU0 ack */
			vpu1_cmd_ack <= 1'b1;	/* VPU1 ack */
		end
		@(posedge clk) start <= 1'b1;	/* Start */
		@(posedge clk) start <= 1'b0;

		wait_pos_clk64();
		wait_pos_clk64();

		@(posedge clk) srst <= 1'b1;	/* Reset traffic generator */
		@(posedge clk) srst <= 1'b0;

		wait_pos_clk4();


		#500 $finish;
	end


	/* Control unit instance */
	vxe_ctrl_unit ctrl_unit(
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
		.o_busy(busy),
		.i_pgm_addr(pgm_addr),
		.o_intr_vld(intr_vld),
		.o_intr(intr),
		.o_last_instr_addr(last_instr_addr),
		.o_last_instr_data(last_instr_data),
		.o_vpu_fault(vpu_fault),
		.i_vpu0_busy(vpu0_busy),
		.i_vpu0_err(vpu0_err),
		.o_vpu0_cmd_sel(vpu0_cmd_sel),
		.i_vpu0_cmd_ack(vpu0_cmd_ack),
		.o_vpu0_cmd_op(vpu0_cmd_op),
		.o_vpu0_cmd_th(vpu0_cmd_th),
		.o_vpu0_cmd_pl(vpu0_cmd_pl),
		.i_vpu1_busy(vpu1_busy),
		.i_vpu1_err(vpu1_err),
		.o_vpu1_cmd_sel(vpu1_cmd_sel),
		.i_vpu1_cmd_ack(vpu1_cmd_ack),
		.o_vpu1_cmd_op(vpu1_cmd_op),
		.o_vpu1_cmd_th(vpu1_cmd_th),
		.o_vpu1_cmd_pl(vpu1_cmd_pl)
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


endmodule /* tb_vxe_ctrl_unit */
