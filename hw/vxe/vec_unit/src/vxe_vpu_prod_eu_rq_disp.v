/*
 * Copyright (c) 2020-2024 The VxEngine Project. All rights reserved.
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
 * VxE VPU requests dispatcher unit
 */


/* Requests dispatcher unit */
module vxe_vpu_prod_eu_rq_disp #(
	parameter IN_DEPTH_POW2 = 2,	/* Incoming FIFOs depth (2^IN_DEPTH_POW2) */
	parameter OUT_DEPTH_POW2 = 2	/* Outgoing FIFOs depth (2^OUT_DEPTH_POW2) */
)
(
	clk,
	nrst,
	/* Control interface */
	i_err_flush,
	o_busy,
	/* Generated address and word enable mask */
	i_rs0_valid,
	i_rs0_addr,
	i_rs0_we_mask,
	o_rs0_incr,
	i_rt0_valid,
	i_rt0_addr,
	i_rt0_we_mask,
	o_rt0_incr,
	i_rs1_valid,
	i_rs1_addr,
	i_rs1_we_mask,
	o_rs1_incr,
	i_rt1_valid,
	i_rt1_addr,
	i_rt1_we_mask,
	o_rt1_incr,
	i_rs2_valid,
	i_rs2_addr,
	i_rs2_we_mask,
	o_rs2_incr,
	i_rt2_valid,
	i_rt2_addr,
	i_rt2_we_mask,
	o_rt2_incr,
	i_rs3_valid,
	i_rs3_addr,
	i_rs3_we_mask,
	o_rs3_incr,
	i_rt3_valid,
	i_rt3_addr,
	i_rt3_we_mask,
	o_rt3_incr,
	i_rs4_valid,
	i_rs4_addr,
	i_rs4_we_mask,
	o_rs4_incr,
	i_rt4_valid,
	i_rt4_addr,
	i_rt4_we_mask,
	o_rt4_incr,
	i_rs5_valid,
	i_rs5_addr,
	i_rs5_we_mask,
	o_rs5_incr,
	i_rt5_valid,
	i_rt5_addr,
	i_rt5_we_mask,
	o_rt5_incr,
	i_rs6_valid,
	i_rs6_addr,
	i_rs6_we_mask,
	o_rs6_incr,
	i_rt6_valid,
	i_rt6_addr,
	i_rt6_we_mask,
	o_rt6_incr,
	i_rs7_valid,
	i_rs7_addr,
	i_rs7_we_mask,
	o_rs7_incr,
	i_rt7_valid,
	i_rt7_addr,
	i_rt7_we_mask,
	o_rt7_incr,
	/* Write enable FIFO interface */
	o_rrq_rs0_we_mask,
	o_rrq_rs0_we_wr,
	i_rrq_rs0_we_rdy,
	o_rrq_rt0_we_mask,
	o_rrq_rt0_we_wr,
	i_rrq_rt0_we_rdy,
	o_rrq_rs1_we_mask,
	o_rrq_rs1_we_wr,
	i_rrq_rs1_we_rdy,
	o_rrq_rt1_we_mask,
	o_rrq_rt1_we_wr,
	i_rrq_rt1_we_rdy,
	o_rrq_rs2_we_mask,
	o_rrq_rs2_we_wr,
	i_rrq_rs2_we_rdy,
	o_rrq_rt2_we_mask,
	o_rrq_rt2_we_wr,
	i_rrq_rt2_we_rdy,
	o_rrq_rs3_we_mask,
	o_rrq_rs3_we_wr,
	i_rrq_rs3_we_rdy,
	o_rrq_rt3_we_mask,
	o_rrq_rt3_we_wr,
	i_rrq_rt3_we_rdy,
	o_rrq_rs4_we_mask,
	o_rrq_rs4_we_wr,
	i_rrq_rs4_we_rdy,
	o_rrq_rt4_we_mask,
	o_rrq_rt4_we_wr,
	i_rrq_rt4_we_rdy,
	o_rrq_rs5_we_mask,
	o_rrq_rs5_we_wr,
	i_rrq_rs5_we_rdy,
	o_rrq_rt5_we_mask,
	o_rrq_rt5_we_wr,
	i_rrq_rt5_we_rdy,
	o_rrq_rs6_we_mask,
	o_rrq_rs6_we_wr,
	i_rrq_rs6_we_rdy,
	o_rrq_rt6_we_mask,
	o_rrq_rt6_we_wr,
	i_rrq_rt6_we_rdy,
	o_rrq_rs7_we_mask,
	o_rrq_rs7_we_wr,
	i_rrq_rs7_we_rdy,
	o_rrq_rt7_we_mask,
	o_rrq_rt7_we_wr,
	i_rrq_rt7_we_rdy,
	/* LSU interface */
	i_rrq_rdy,
	o_rrq_wr,
	o_rrq_th,
	o_rrq_addr,
	o_rrq_arg
);
/* Rx FSM states */
localparam	FSM_RX_IDLE = 2'b00;		/* Idle */
localparam	FSM_RX_RECV = 2'b01;		/* Receive request */
localparam	FSM_RX_STALL = 2'b10;		/* Stall on congestion */
localparam	FSM_RX_FLUSH = 2'b11;		/* Flush on error */
/* Scheduler FSM states */
localparam	FSM_SCH_IDLE = 5'b00000;	/* Idle */
localparam	FSM_SCH_ST00 = 5'b10000;	/* Rs0 */
localparam	FSM_SCH_ST01 = 5'b10001;	/* Rt0 */
localparam	FSM_SCH_ST02 = 5'b10010;	/* Rs1 */
localparam	FSM_SCH_ST03 = 5'b10011;	/* Rt1 */
localparam	FSM_SCH_ST04 = 5'b10100;	/* Rs2 */
localparam	FSM_SCH_ST05 = 5'b10101;	/* Rt2 */
localparam	FSM_SCH_ST06 = 5'b10110;	/* Rs3 */
localparam	FSM_SCH_ST07 = 5'b10111;	/* Rt3 */
localparam	FSM_SCH_ST08 = 5'b11000;	/* Rs4 */
localparam	FSM_SCH_ST09 = 5'b11001;	/* Rt4 */
localparam	FSM_SCH_ST0A = 5'b11010;	/* Rs5 */
localparam	FSM_SCH_ST0B = 5'b11011;	/* Rt5 */
localparam	FSM_SCH_ST0C = 5'b11100;	/* Rs6 */
localparam	FSM_SCH_ST0D = 5'b11101;	/* Rt6 */
localparam	FSM_SCH_ST0E = 5'b11110;	/* Rs7 */
localparam	FSM_SCH_ST0F = 5'b11111;	/* Rt7 */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Control interface */
input wire		i_err_flush;
output wire		o_busy;
/* Generated address and word enable mask */
input wire		i_rs0_valid;
input wire [36:0]	i_rs0_addr;
input wire [1:0]	i_rs0_we_mask;
output wire		o_rs0_incr;
input wire		i_rt0_valid;
input wire [36:0]	i_rt0_addr;
input wire [1:0]	i_rt0_we_mask;
output wire		o_rt0_incr;
input wire		i_rs1_valid;
input wire [36:0]	i_rs1_addr;
input wire [1:0]	i_rs1_we_mask;
output wire		o_rs1_incr;
input wire		i_rt1_valid;
input wire [36:0]	i_rt1_addr;
input wire [1:0]	i_rt1_we_mask;
output wire		o_rt1_incr;
input wire		i_rs2_valid;
input wire [36:0]	i_rs2_addr;
input wire [1:0]	i_rs2_we_mask;
output wire		o_rs2_incr;
input wire		i_rt2_valid;
input wire [36:0]	i_rt2_addr;
input wire [1:0]	i_rt2_we_mask;
output wire		o_rt2_incr;
input wire		i_rs3_valid;
input wire [36:0]	i_rs3_addr;
input wire [1:0]	i_rs3_we_mask;
output wire		o_rs3_incr;
input wire		i_rt3_valid;
input wire [36:0]	i_rt3_addr;
input wire [1:0]	i_rt3_we_mask;
output wire		o_rt3_incr;
input wire		i_rs4_valid;
input wire [36:0]	i_rs4_addr;
input wire [1:0]	i_rs4_we_mask;
output wire		o_rs4_incr;
input wire		i_rt4_valid;
input wire [36:0]	i_rt4_addr;
input wire [1:0]	i_rt4_we_mask;
output wire		o_rt4_incr;
input wire		i_rs5_valid;
input wire [36:0]	i_rs5_addr;
input wire [1:0]	i_rs5_we_mask;
output wire		o_rs5_incr;
input wire		i_rt5_valid;
input wire [36:0]	i_rt5_addr;
input wire [1:0]	i_rt5_we_mask;
output wire		o_rt5_incr;
input wire		i_rs6_valid;
input wire [36:0]	i_rs6_addr;
input wire [1:0]	i_rs6_we_mask;
output wire		o_rs6_incr;
input wire		i_rt6_valid;
input wire [36:0]	i_rt6_addr;
input wire [1:0]	i_rt6_we_mask;
output wire		o_rt6_incr;
input wire		i_rs7_valid;
input wire [36:0]	i_rs7_addr;
input wire [1:0]	i_rs7_we_mask;
output wire		o_rs7_incr;
input wire		i_rt7_valid;
input wire [36:0]	i_rt7_addr;
input wire [1:0]	i_rt7_we_mask;
output wire		o_rt7_incr;
/* Write enable FIFO interface */
output wire [1:0]	o_rrq_rs0_we_mask;
output wire		o_rrq_rs0_we_wr;
input wire		i_rrq_rs0_we_rdy;
output wire [1:0]	o_rrq_rt0_we_mask;
output wire		o_rrq_rt0_we_wr;
input wire		i_rrq_rt0_we_rdy;
output wire [1:0]	o_rrq_rs1_we_mask;
output wire		o_rrq_rs1_we_wr;
input wire		i_rrq_rs1_we_rdy;
output wire [1:0]	o_rrq_rt1_we_mask;
output wire		o_rrq_rt1_we_wr;
input wire		i_rrq_rt1_we_rdy;
output wire [1:0]	o_rrq_rs2_we_mask;
output wire		o_rrq_rs2_we_wr;
input wire		i_rrq_rs2_we_rdy;
output wire [1:0]	o_rrq_rt2_we_mask;
output wire		o_rrq_rt2_we_wr;
input wire		i_rrq_rt2_we_rdy;
output wire [1:0]	o_rrq_rs3_we_mask;
output wire		o_rrq_rs3_we_wr;
input wire		i_rrq_rs3_we_rdy;
output wire [1:0]	o_rrq_rt3_we_mask;
output wire		o_rrq_rt3_we_wr;
input wire		i_rrq_rt3_we_rdy;
output wire [1:0]	o_rrq_rs4_we_mask;
output wire		o_rrq_rs4_we_wr;
input wire		i_rrq_rs4_we_rdy;
output wire [1:0]	o_rrq_rt4_we_mask;
output wire		o_rrq_rt4_we_wr;
input wire		i_rrq_rt4_we_rdy;
output wire [1:0]	o_rrq_rs5_we_mask;
output wire		o_rrq_rs5_we_wr;
input wire		i_rrq_rs5_we_rdy;
output wire [1:0]	o_rrq_rt5_we_mask;
output wire		o_rrq_rt5_we_wr;
input wire		i_rrq_rt5_we_rdy;
output wire [1:0]	o_rrq_rs6_we_mask;
output wire		o_rrq_rs6_we_wr;
input wire		i_rrq_rs6_we_rdy;
output wire [1:0]	o_rrq_rt6_we_mask;
output wire		o_rrq_rt6_we_wr;
input wire		i_rrq_rt6_we_rdy;
output wire [1:0]	o_rrq_rs7_we_mask;
output wire		o_rrq_rs7_we_wr;
input wire		i_rrq_rs7_we_rdy;
output wire [1:0]	o_rrq_rt7_we_mask;
output wire		o_rrq_rt7_we_wr;
input wire		i_rrq_rt7_we_rdy;
/* LSU interface */
input wire		i_rrq_rdy;
output reg		o_rrq_wr;
output reg [2:0]	o_rrq_th;
output reg [36:0]	o_rrq_addr;
output reg		o_rrq_arg;


genvar i, j;	/* Generator block vars */


/* At least one of input FIFOs is not empty */
wire in_fifo_busy = !t[0].r[0].rq_fifo_empty || !t[0].r[0].we_fifo_empty ||
	!t[0].r[1].rq_fifo_empty || !t[0].r[1].we_fifo_empty ||
	!t[1].r[0].rq_fifo_empty || !t[1].r[0].we_fifo_empty ||
	!t[1].r[1].rq_fifo_empty || !t[1].r[1].we_fifo_empty ||
	!t[2].r[0].rq_fifo_empty || !t[2].r[0].we_fifo_empty ||
	!t[2].r[1].rq_fifo_empty || !t[2].r[1].we_fifo_empty ||
	!t[3].r[0].rq_fifo_empty || !t[3].r[0].we_fifo_empty ||
	!t[3].r[1].rq_fifo_empty || !t[3].r[1].we_fifo_empty ||
	!t[4].r[0].rq_fifo_empty || !t[4].r[0].we_fifo_empty ||
	!t[4].r[1].rq_fifo_empty || !t[4].r[1].we_fifo_empty ||
	!t[5].r[0].rq_fifo_empty || !t[5].r[0].we_fifo_empty ||
	!t[5].r[1].rq_fifo_empty || !t[5].r[1].we_fifo_empty ||
	!t[6].r[0].rq_fifo_empty || !t[6].r[0].we_fifo_empty ||
	!t[6].r[1].rq_fifo_empty || !t[6].r[1].we_fifo_empty ||
	!t[7].r[0].rq_fifo_empty || !t[7].r[0].we_fifo_empty ||
	!t[7].r[1].rq_fifo_empty || !t[7].r[1].we_fifo_empty;
/* Output FIFO is not empty */
wire out_fifo_busy = !rrq_fifo_empty;
/* At least one of input FSMs is busy */
wire in_fsm_busy = t[0].r[0].fsm_rx_busy || t[0].r[1].fsm_rx_busy ||
	t[1].r[0].fsm_rx_busy || t[1].r[1].fsm_rx_busy ||
	t[2].r[0].fsm_rx_busy || t[2].r[1].fsm_rx_busy ||
	t[3].r[0].fsm_rx_busy || t[3].r[1].fsm_rx_busy ||
	t[4].r[0].fsm_rx_busy || t[4].r[1].fsm_rx_busy ||
	t[5].r[0].fsm_rx_busy || t[5].r[1].fsm_rx_busy ||
	t[6].r[0].fsm_rx_busy || t[6].r[1].fsm_rx_busy ||
	t[7].r[0].fsm_rx_busy || t[7].r[1].fsm_rx_busy;
/* Request scheduling FSM is busy */
wire sch_fsm_busy = fsm_sch_busy;
/* LSU read request dispatch FSM is busy */
wire lsu_rrq_fsm_busy = fsm_lsu_rrq_busy;
/* At least one of WE (word enable) FSMs is busy */
wire we_fsm_busy = t_we[0].r[0].fsm_we_busy || t_we[0].r[1].fsm_we_busy ||
	t_we[1].r[0].fsm_we_busy || t_we[1].r[1].fsm_we_busy ||
	t_we[2].r[0].fsm_we_busy || t_we[2].r[1].fsm_we_busy ||
	t_we[3].r[0].fsm_we_busy || t_we[3].r[1].fsm_we_busy ||
	t_we[4].r[0].fsm_we_busy || t_we[4].r[1].fsm_we_busy ||
	t_we[5].r[0].fsm_we_busy || t_we[5].r[1].fsm_we_busy ||
	t_we[6].r[0].fsm_we_busy || t_we[6].r[1].fsm_we_busy ||
	t_we[7].r[0].fsm_we_busy || t_we[7].r[1].fsm_we_busy;

/* Global busy state */
assign o_busy = in_fifo_busy || out_fifo_busy || in_fsm_busy || sch_fsm_busy ||
	lsu_rrq_fsm_busy || we_fsm_busy;

/* Flush on error busy state */
wire err_flush_busy = in_fifo_busy || out_fifo_busy || sch_fsm_busy ||
	lsu_rrq_fsm_busy || we_fsm_busy;



/*************** Generate per thread, per argument Rx FSMs ***************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		/* Block inputs/outputs */
		wire		i_valid;
		wire [36:0]	i_addr;
		wire [1:0]	i_we_mask;
		reg		o_incr;

		/*** Vector data request FIFO ***/
		reg [36:0]		rq_fifo[0:2**IN_DEPTH_POW2-1];
		reg [IN_DEPTH_POW2:0]	rq_fifo_rp;	/* Read pointer */
		reg [IN_DEPTH_POW2:0]	rq_fifo_wp;	/* Write pointer */
		/* Previous FIFO read pointer */
		wire [IN_DEPTH_POW2:0]	rq_fifo_pre_rp = rq_fifo_rp - 1'b1;
		/* FIFO states */
		wire rq_fifo_empty = (rq_fifo_rp[IN_DEPTH_POW2] == rq_fifo_wp[IN_DEPTH_POW2]) &&
			(rq_fifo_rp[IN_DEPTH_POW2-1:0] == rq_fifo_wp[IN_DEPTH_POW2-1:0]);
		wire rq_fifo_full = (rq_fifo_rp[IN_DEPTH_POW2] != rq_fifo_wp[IN_DEPTH_POW2]) &&
			(rq_fifo_rp[IN_DEPTH_POW2-1:0] == rq_fifo_wp[IN_DEPTH_POW2-1:0]);
		wire rq_fifo_pre_full = (rq_fifo_pre_rp[IN_DEPTH_POW2] != rq_fifo_wp[IN_DEPTH_POW2]) &&
			(rq_fifo_pre_rp[IN_DEPTH_POW2-1:0] == rq_fifo_wp[IN_DEPTH_POW2-1:0]);
		/* FIFO stall */
		wire rq_fifo_stall = rq_fifo_full || rq_fifo_pre_full;

		/*** Word enable FIFO ***/
		reg [1:0]		we_fifo[0:2**IN_DEPTH_POW2-1];
		reg [IN_DEPTH_POW2:0]	we_fifo_rp;	/* Read pointer */
		reg [IN_DEPTH_POW2:0]	we_fifo_wp;	/* Write pointer */
		/* Previous FIFO read pointer */
		wire [IN_DEPTH_POW2:0]	we_fifo_pre_rp = we_fifo_rp - 1'b1;
		/* FIFO states */
		wire we_fifo_empty = (we_fifo_rp[IN_DEPTH_POW2] == we_fifo_wp[IN_DEPTH_POW2]) &&
			(we_fifo_rp[IN_DEPTH_POW2-1:0] == we_fifo_wp[IN_DEPTH_POW2-1:0]);
		wire we_fifo_full = (we_fifo_rp[IN_DEPTH_POW2] != we_fifo_wp[IN_DEPTH_POW2]) &&
			(we_fifo_rp[IN_DEPTH_POW2-1:0] == we_fifo_wp[IN_DEPTH_POW2-1:0]);
		wire we_fifo_pre_full = (we_fifo_pre_rp[IN_DEPTH_POW2] != we_fifo_wp[IN_DEPTH_POW2]) &&
			(we_fifo_pre_rp[IN_DEPTH_POW2-1:0] == we_fifo_wp[IN_DEPTH_POW2-1:0]);
		/* FIFO stall */
		wire we_fifo_stall = we_fifo_full || we_fifo_pre_full;


		/* Rx FSM */
		wire fsm_rx_busy = (fsm_rx != FSM_RX_IDLE);
		reg [1:0] fsm_rx;

		always @(posedge clk or negedge nrst)
		begin
			if(!nrst)
			begin
				fsm_rx <= FSM_RX_IDLE;
				rq_fifo_wp <= {(IN_DEPTH_POW2+1){1'b0}};
				we_fifo_wp <= {(IN_DEPTH_POW2+1){1'b0}};
				o_incr <= 1'b0;
			end
			else
			case(fsm_rx)
			FSM_RX_IDLE: begin
				if(i_valid)
				begin
					fsm_rx <= FSM_RX_RECV;
					o_incr <= 1'b1;
				end

				/* Check for error state */
				if(i_err_flush)
				begin
					fsm_rx <= FSM_RX_FLUSH;
					o_incr <= 1'b1;
				end
			end
			FSM_RX_RECV: begin
				if(i_valid)
				begin
					rq_fifo[rq_fifo_wp[IN_DEPTH_POW2-1:0]] <= i_addr;
					we_fifo[we_fifo_wp[IN_DEPTH_POW2-1:0]] <= i_we_mask;
					rq_fifo_wp <= rq_fifo_wp + 1'b1;
					we_fifo_wp <= we_fifo_wp + 1'b1;

					if(rq_fifo_stall || we_fifo_stall)
					begin
						fsm_rx <= FSM_RX_STALL;
						o_incr <= 1'b0;
					end
				end
				else
				begin
					/* Address sequence generation completed */
					fsm_rx <= FSM_RX_IDLE;
					o_incr <= 1'b0;
				end

				/* Check for error state */
				if(i_err_flush)
				begin
					fsm_rx <= FSM_RX_FLUSH;
					o_incr <= 1'b1;
				end
			end
			FSM_RX_STALL: begin
				if(!(rq_fifo_stall || we_fifo_stall))
				begin
					if(i_valid)
					begin
						fsm_rx <= FSM_RX_RECV;
						o_incr <= 1'b1;
					end
					else
					begin
						/* Done */
						fsm_rx <= FSM_RX_IDLE;
					end
				end

				/* Check for error state */
				if(i_err_flush)
				begin
					fsm_rx <= FSM_RX_FLUSH;
					o_incr <= 1'b1;
				end
			end
			FSM_RX_FLUSH: begin
				if(!i_valid && !err_flush_busy)
				begin
					fsm_rx <= FSM_RX_IDLE;
					o_incr <= 1'b0;
				end
			end
			default: ;
			endcase
		end
	end	/* for(j, ...) */
end	/* for(i, ...) */

endgenerate


/*** Connect generated blocks ***/

/* Thread 0, Rs */
assign t[0].r[0].i_valid = i_rs0_valid;
assign t[0].r[0].i_addr = i_rs0_addr;
assign t[0].r[0].i_we_mask = i_rs0_we_mask;
assign o_rs0_incr = t[0].r[0].o_incr;
/* Thread 0, Rt */
assign t[0].r[1].i_valid = i_rt0_valid;
assign t[0].r[1].i_addr = i_rt0_addr;
assign t[0].r[1].i_we_mask = i_rt0_we_mask;
assign o_rt0_incr = t[0].r[1].o_incr;
/* Thread 1, Rs */
assign t[1].r[0].i_valid = i_rs1_valid;
assign t[1].r[0].i_addr = i_rs1_addr;
assign t[1].r[0].i_we_mask = i_rs1_we_mask;
assign o_rs1_incr = t[1].r[0].o_incr;
/* Thread 1, Rt */
assign t[1].r[1].i_valid = i_rt1_valid;
assign t[1].r[1].i_addr = i_rt1_addr;
assign t[1].r[1].i_we_mask = i_rt1_we_mask;
assign o_rt1_incr = t[1].r[1].o_incr;
/* Thread 2, Rs */
assign t[2].r[0].i_valid = i_rs2_valid;
assign t[2].r[0].i_addr = i_rs2_addr;
assign t[2].r[0].i_we_mask = i_rs2_we_mask;
assign o_rs2_incr = t[2].r[0].o_incr;
/* Thread 2, Rt */
assign t[2].r[1].i_valid = i_rt2_valid;
assign t[2].r[1].i_addr = i_rt2_addr;
assign t[2].r[1].i_we_mask = i_rt2_we_mask;
assign o_rt2_incr = t[2].r[1].o_incr;
/* Thread 3, Rs */
assign t[3].r[0].i_valid = i_rs3_valid;
assign t[3].r[0].i_addr = i_rs3_addr;
assign t[3].r[0].i_we_mask = i_rs3_we_mask;
assign o_rs3_incr = t[3].r[0].o_incr;
/* Thread 3, Rt */
assign t[3].r[1].i_valid = i_rt3_valid;
assign t[3].r[1].i_addr = i_rt3_addr;
assign t[3].r[1].i_we_mask = i_rt3_we_mask;
assign o_rt3_incr = t[3].r[1].o_incr;
/* Thread 4, Rs */
assign t[4].r[0].i_valid = i_rs4_valid;
assign t[4].r[0].i_addr = i_rs4_addr;
assign t[4].r[0].i_we_mask = i_rs4_we_mask;
assign o_rs4_incr = t[4].r[0].o_incr;
/* Thread 4, Rt */
assign t[4].r[1].i_valid = i_rt4_valid;
assign t[4].r[1].i_addr = i_rt4_addr;
assign t[4].r[1].i_we_mask = i_rt4_we_mask;
assign o_rt4_incr = t[4].r[1].o_incr;
/* Thread 5, Rs */
assign t[5].r[0].i_valid = i_rs5_valid;
assign t[5].r[0].i_addr = i_rs5_addr;
assign t[5].r[0].i_we_mask = i_rs5_we_mask;
assign o_rs5_incr = t[5].r[0].o_incr;
/* Thread 5, Rt */
assign t[5].r[1].i_valid = i_rt5_valid;
assign t[5].r[1].i_addr = i_rt5_addr;
assign t[5].r[1].i_we_mask = i_rt5_we_mask;
assign o_rt5_incr = t[5].r[1].o_incr;
/* Thread 6, Rs */
assign t[6].r[0].i_valid = i_rs6_valid;
assign t[6].r[0].i_addr = i_rs6_addr;
assign t[6].r[0].i_we_mask = i_rs6_we_mask;
assign o_rs6_incr = t[6].r[0].o_incr;
/* Thread 6, Rt */
assign t[6].r[1].i_valid = i_rt6_valid;
assign t[6].r[1].i_addr = i_rt6_addr;
assign t[6].r[1].i_we_mask = i_rt6_we_mask;
assign o_rt6_incr = t[6].r[1].o_incr;
/* Thread 7, Rs */
assign t[7].r[0].i_valid = i_rs7_valid;
assign t[7].r[0].i_addr = i_rs7_addr;
assign t[7].r[0].i_we_mask = i_rs7_we_mask;
assign o_rs7_incr = t[7].r[0].o_incr;
/* Thread 7, Rt */
assign t[7].r[1].i_valid = i_rt7_valid;
assign t[7].r[1].i_addr = i_rt7_addr;
assign t[7].r[1].i_we_mask = i_rt7_we_mask;
assign o_rt7_incr = t[7].r[1].o_incr;



/* Conditions for scheduling pending requests */
wire ST_0_F_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_1_F_valid = |{
	/***********************/ !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_2_F_valid = |{
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_3_F_valid = |{
	/***********************/ !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_4_F_valid = |{
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_5_F_valid = |{
	/***********************/ !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_6_F_valid = |{
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_7_F_valid = |{
	/***********************/ !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_8_F_valid = |{
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_9_F_valid = |{
	/***********************/ !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_A_F_valid = |{
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_B_F_valid = |{
	/***********************/ !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_C_F_valid = |{
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_D_F_valid = |{
	/***********************/ !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_E_F_valid = |{
	!t[7].r[0].rq_fifo_empty, !t[7].r[1].rq_fifo_empty
};

wire ST_F_F_valid = |{
	/***********************/ !t[7].r[1].rq_fifo_empty
};

wire ST_0_0_valid = |{
	!t[0].r[0].rq_fifo_empty  /***********************/
};

wire ST_0_1_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty
};

wire ST_0_2_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty  /***********************/
};

wire ST_0_3_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty
};

wire ST_0_4_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty  /***********************/
};

wire ST_0_5_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty
};

wire ST_0_6_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty  /***********************/
};

wire ST_0_7_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty
};

wire ST_0_8_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty  /***********************/
};

wire ST_0_9_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty
};

wire ST_0_A_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty  /***********************/
};

wire ST_0_B_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty
};

wire ST_0_C_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty  /***********************/
};

wire ST_0_D_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty
};

wire ST_0_E_valid = |{
	!t[0].r[0].rq_fifo_empty, !t[0].r[1].rq_fifo_empty,
	!t[1].r[0].rq_fifo_empty, !t[1].r[1].rq_fifo_empty,
	!t[2].r[0].rq_fifo_empty, !t[2].r[1].rq_fifo_empty,
	!t[3].r[0].rq_fifo_empty, !t[3].r[1].rq_fifo_empty,
	!t[4].r[0].rq_fifo_empty, !t[4].r[1].rq_fifo_empty,
	!t[5].r[0].rq_fifo_empty, !t[5].r[1].rq_fifo_empty,
	!t[6].r[0].rq_fifo_empty, !t[6].r[1].rq_fifo_empty,
	!t[7].r[0].rq_fifo_empty  /***********************/
};



/*************** Request scheduler ***************/

/*** Memory read request FIFO ***/
reg [40:0]		rrq_fifo[0:2**OUT_DEPTH_POW2-1];
reg [OUT_DEPTH_POW2:0]	rrq_fifo_rp;	/* Read pointer */
reg [OUT_DEPTH_POW2:0]	rrq_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [OUT_DEPTH_POW2:0]	rrq_fifo_pre_rp = rrq_fifo_rp - 1'b1;
/* FIFO states */
wire rrq_fifo_empty = (rrq_fifo_rp[OUT_DEPTH_POW2-1:0] == rrq_fifo_wp[OUT_DEPTH_POW2-1:0]) &&
	(rrq_fifo_rp[OUT_DEPTH_POW2] == rrq_fifo_wp[OUT_DEPTH_POW2]);
wire rrq_fifo_full = (rrq_fifo_rp[OUT_DEPTH_POW2-1:0] == rrq_fifo_wp[OUT_DEPTH_POW2-1:0]) &&
	(rrq_fifo_rp[OUT_DEPTH_POW2] != rrq_fifo_wp[OUT_DEPTH_POW2]);
wire rrq_fifo_pre_full = (rrq_fifo_pre_rp[OUT_DEPTH_POW2-1:0] == rrq_fifo_wp[OUT_DEPTH_POW2-1:0]) &&
	(rrq_fifo_pre_rp[OUT_DEPTH_POW2] != rrq_fifo_wp[OUT_DEPTH_POW2]);
/* FIFO stall */
wire rrq_fifo_stall = rrq_fifo_full || rrq_fifo_pre_full;


wire fsm_sch_busy = (fsm_sch != FSM_SCH_IDLE);

reg [4:0] fsm_sch;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_sch <= FSM_SCH_IDLE;
		rrq_fifo_wp <= {(OUT_DEPTH_POW2+1){1'b0}};
		t[0].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[0].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[1].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[1].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[2].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[2].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[3].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[3].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[4].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[4].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[5].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[5].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[6].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[6].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[7].r[0].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
		t[7].r[1].rq_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
	end
	else
	case(fsm_sch)
	FSM_SCH_IDLE: begin
		if(ST_0_F_valid)
			fsm_sch <= FSM_SCH_ST00;
	end
	/* Thread 0 */
	FSM_SCH_ST00: begin
		if(!t[0].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[0].r[0].rq_fifo[t[0].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h0,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[0].r[0].rq_fifo_rp <= t[0].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_1_F_valid)
					fsm_sch <= FSM_SCH_ST01;
			end
		end
		else if(ST_1_F_valid)
			fsm_sch <= FSM_SCH_ST01;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST01: begin
		if(!t[0].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[0].r[1].rq_fifo[t[0].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h0,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[0].r[1].rq_fifo_rp <= t[0].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_2_F_valid)
					fsm_sch <= FSM_SCH_ST02;
				else if(ST_0_0_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_2_F_valid)
			fsm_sch <= FSM_SCH_ST02;
		else if(ST_0_0_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	/* Thread 1 */
	FSM_SCH_ST02: begin
		if(!t[1].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[1].r[0].rq_fifo[t[1].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h1,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[1].r[0].rq_fifo_rp <= t[1].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_3_F_valid)
					fsm_sch <= FSM_SCH_ST03;
				else if(ST_0_1_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_3_F_valid)
			fsm_sch <= FSM_SCH_ST03;
		else if(ST_0_1_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST03: begin
		if(!t[1].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[1].r[1].rq_fifo[t[1].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h1,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[1].r[1].rq_fifo_rp <= t[1].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_4_F_valid)
					fsm_sch <= FSM_SCH_ST04;
				else if(ST_0_2_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_4_F_valid)
			fsm_sch <= FSM_SCH_ST04;
		else if(ST_0_2_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	/* Thread 2 */
	FSM_SCH_ST04: begin
		if(!t[2].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[2].r[0].rq_fifo[t[2].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h2,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[2].r[0].rq_fifo_rp <= t[2].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_5_F_valid)
					fsm_sch <= FSM_SCH_ST05;
				else if(ST_0_3_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_5_F_valid)
			fsm_sch <= FSM_SCH_ST05;
		else if(ST_0_3_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST05: begin
		if(!t[2].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[2].r[1].rq_fifo[t[2].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h2,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[2].r[1].rq_fifo_rp <= t[2].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_6_F_valid)
					fsm_sch <= FSM_SCH_ST06;
				else if(ST_0_4_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_6_F_valid)
			fsm_sch <= FSM_SCH_ST06;
		else if(ST_0_4_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	/* Thread 3 */
	FSM_SCH_ST06: begin
		if(!t[3].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[3].r[0].rq_fifo[t[3].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h3,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[3].r[0].rq_fifo_rp <= t[3].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_7_F_valid)
					fsm_sch <= FSM_SCH_ST07;
				else if(ST_0_5_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_7_F_valid)
			fsm_sch <= FSM_SCH_ST07;
		else if(ST_0_5_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST07: begin
		if(!t[3].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[3].r[1].rq_fifo[t[3].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h3,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[3].r[1].rq_fifo_rp <= t[3].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_8_F_valid)
					fsm_sch <= FSM_SCH_ST08;
				else if(ST_0_6_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_8_F_valid)
			fsm_sch <= FSM_SCH_ST08;
		else if(ST_0_6_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	/* Thread 4 */
	FSM_SCH_ST08: begin
		if(!t[4].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[4].r[0].rq_fifo[t[4].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h4,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[4].r[0].rq_fifo_rp <= t[4].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_9_F_valid)
					fsm_sch <= FSM_SCH_ST09;
				else if(ST_0_7_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_9_F_valid)
			fsm_sch <= FSM_SCH_ST09;
		else if(ST_0_7_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST09: begin
		if(!t[4].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[4].r[1].rq_fifo[t[4].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h4,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[4].r[1].rq_fifo_rp <= t[4].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_A_F_valid)
					fsm_sch <= FSM_SCH_ST0A;
				else if(ST_0_8_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_A_F_valid)
			fsm_sch <= FSM_SCH_ST0A;
		else if(ST_0_8_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	/* Thread 5 */
	FSM_SCH_ST0A: begin
		if(!t[5].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[5].r[0].rq_fifo[t[5].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h5,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[5].r[0].rq_fifo_rp <= t[5].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_B_F_valid)
					fsm_sch <= FSM_SCH_ST0B;
				else if(ST_0_9_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_B_F_valid)
			fsm_sch <= FSM_SCH_ST0B;
		else if(ST_0_9_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST0B: begin
		if(!t[5].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[5].r[1].rq_fifo[t[5].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h5,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[5].r[1].rq_fifo_rp <= t[5].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_C_F_valid)
					fsm_sch <= FSM_SCH_ST0C;
				else if(ST_0_A_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_C_F_valid)
			fsm_sch <= FSM_SCH_ST0C;
		else if(ST_0_A_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	/* Thread 6 */
	FSM_SCH_ST0C: begin
		if(!t[6].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[6].r[0].rq_fifo[t[6].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h6,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[6].r[0].rq_fifo_rp <= t[6].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_D_F_valid)
					fsm_sch <= FSM_SCH_ST0D;
				else if(ST_0_B_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_D_F_valid)
			fsm_sch <= FSM_SCH_ST0D;
		else if(ST_0_B_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST0D: begin
		if(!t[6].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[6].r[1].rq_fifo[t[6].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h6,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[6].r[1].rq_fifo_rp <= t[6].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_E_F_valid)
					fsm_sch <= FSM_SCH_ST0E;
				else if(ST_0_C_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_E_F_valid)
			fsm_sch <= FSM_SCH_ST0E;
		else if(ST_0_C_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	/* Thread 7 */
	FSM_SCH_ST0E: begin
		if(!t[7].r[0].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[7].r[0].rq_fifo[t[7].r[0].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h7,
					1'b0
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[7].r[0].rq_fifo_rp <= t[7].r[0].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_F_F_valid)
					fsm_sch <= FSM_SCH_ST0F;
				else if(ST_0_D_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_F_F_valid)
			fsm_sch <= FSM_SCH_ST0F;
		else if(ST_0_D_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	FSM_SCH_ST0F: begin
		if(!t[7].r[1].rq_fifo_empty)
		begin
			if(!rrq_fifo_full)
			begin
				/* Upstream request */
				rrq_fifo[rrq_fifo_wp[OUT_DEPTH_POW2-1:0]] <= {
					t[7].r[1].rq_fifo[t[7].r[1].rq_fifo_rp[IN_DEPTH_POW2-1:0]],
					3'h7,
					1'b1
				};
				rrq_fifo_wp <= rrq_fifo_wp + 1'b1;
				t[7].r[1].rq_fifo_rp <= t[7].r[1].rq_fifo_rp + 1'b1;

				/* Next state */
				if(ST_0_E_valid)
					fsm_sch <= FSM_SCH_ST00;
			end
		end
		else if(ST_0_F_valid)
			fsm_sch <= FSM_SCH_ST00;
		else
			fsm_sch <= FSM_SCH_IDLE;
	end
	default: ;
	endcase
end



/*************** LSU Read request ***************/

wire [2:0]	rrq_th;
wire [36:0]	rrq_addr;
wire		rrq_arg;
assign { rrq_addr, rrq_th, rrq_arg } = rrq_fifo[rrq_fifo_rp[OUT_DEPTH_POW2-1:0]];


wire fsm_lsu_rrq_busy = (fsm_lsu_rrq != 1'b0);

reg fsm_lsu_rrq;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_lsu_rrq <= 1'b0;
		rrq_fifo_rp <= {(OUT_DEPTH_POW2+1){1'b0}};
		o_rrq_wr <= 1'b0;
	end
	else if(fsm_lsu_rrq == 1'b0)
	begin
		if(!rrq_fifo_empty)
		begin
			o_rrq_wr <= 1'b1;
			o_rrq_th <= rrq_th;
			o_rrq_addr <= rrq_addr;
			o_rrq_arg <= rrq_arg;
			rrq_fifo_rp <= rrq_fifo_rp + 1'b1;
			fsm_lsu_rrq <= 1'b1;
		end
	end
	else if(fsm_lsu_rrq == 1'b1)
	begin
		if(i_rrq_rdy && !rrq_fifo_empty)
		begin
			o_rrq_th <= rrq_th;
			o_rrq_addr <= rrq_addr;
			o_rrq_arg <= rrq_arg;
			rrq_fifo_rp <= rrq_fifo_rp + 1'b1;
		end
		else if(i_rrq_rdy && rrq_fifo_empty)
		begin
			fsm_lsu_rrq <= 1'b0;
			o_rrq_wr <= 1'b0;
		end
	end
end



/*************** Generate per thread, per argument WE FSMs ***************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t_we
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		/* Block inputs/outputs */
		reg [1:0]	o_rrq_we_mask;
		reg		o_rrq_we_wr;
		wire		i_rrq_we_rdy;

		/* WE FSM */
		wire fsm_we_busy = (fsm_we != 1'b0);
		reg fsm_we;

		always @(posedge clk or negedge nrst)
		begin
			if(!nrst)
			begin
				fsm_we <= 1'b0;
				t[i].r[j].we_fifo_rp <= {(IN_DEPTH_POW2+1){1'b0}};
				o_rrq_we_wr <= 1'b0;
			end
			else if(fsm_we == 1'b0)
			begin
				if(!t[i].r[j].we_fifo_empty)
				begin
					o_rrq_we_wr <= 1'b1;
					o_rrq_we_mask <= t[i].r[j].we_fifo[t[i].r[j].we_fifo_rp[IN_DEPTH_POW2-1:0]];
					t[i].r[j].we_fifo_rp <= t[i].r[j].we_fifo_rp + 1'b1;
					fsm_we <= 1'b1;
				end
			end
			else if(fsm_we == 1'b1)
			begin
				if(i_rrq_we_rdy && !t[i].r[j].we_fifo_empty)
				begin
					o_rrq_we_mask <= t[i].r[j].we_fifo[t[i].r[j].we_fifo_rp[IN_DEPTH_POW2-1:0]];
					t[i].r[j].we_fifo_rp <= t[i].r[j].we_fifo_rp + 1'b1;
				end
				else if(i_rrq_we_rdy && t[i].r[j].we_fifo_empty)
				begin
					fsm_we <= 1'b0;
					o_rrq_we_wr <= 1'b0;
				end
			end
		end
	end	/* for(j, ...) */
end	/* for(i, ...) */

endgenerate


/*** Connect generated blocks ***/

/* Thread 0, Rs */
assign o_rrq_rs0_we_mask = t_we[0].r[0].o_rrq_we_mask;
assign o_rrq_rs0_we_wr = t_we[0].r[0].o_rrq_we_wr;
assign t_we[0].r[0].i_rrq_we_rdy = i_rrq_rs0_we_rdy;
/* Thread 0, Rt */
assign o_rrq_rt0_we_mask = t_we[0].r[1].o_rrq_we_mask;
assign o_rrq_rt0_we_wr = t_we[0].r[1].o_rrq_we_wr;
assign t_we[0].r[1].i_rrq_we_rdy = i_rrq_rt0_we_rdy;
/* Thread 1, Rs */
assign o_rrq_rs1_we_mask = t_we[1].r[0].o_rrq_we_mask;
assign o_rrq_rs1_we_wr = t_we[1].r[0].o_rrq_we_wr;
assign t_we[1].r[0].i_rrq_we_rdy = i_rrq_rs1_we_rdy;
/* Thread 1, Rt */
assign o_rrq_rt1_we_mask = t_we[1].r[1].o_rrq_we_mask;
assign o_rrq_rt1_we_wr = t_we[1].r[1].o_rrq_we_wr;
assign t_we[1].r[1].i_rrq_we_rdy = i_rrq_rt1_we_rdy;
/* Thread 2, Rs */
assign o_rrq_rs2_we_mask = t_we[2].r[0].o_rrq_we_mask;
assign o_rrq_rs2_we_wr = t_we[2].r[0].o_rrq_we_wr;
assign t_we[2].r[0].i_rrq_we_rdy = i_rrq_rs2_we_rdy;
/* Thread 2, Rt */
assign o_rrq_rt2_we_mask = t_we[2].r[1].o_rrq_we_mask;
assign o_rrq_rt2_we_wr = t_we[2].r[1].o_rrq_we_wr;
assign t_we[2].r[1].i_rrq_we_rdy = i_rrq_rt2_we_rdy;
/* Thread 3, Rs */
assign o_rrq_rs3_we_mask = t_we[3].r[0].o_rrq_we_mask;
assign o_rrq_rs3_we_wr = t_we[3].r[0].o_rrq_we_wr;
assign t_we[3].r[0].i_rrq_we_rdy = i_rrq_rs3_we_rdy;
/* Thread 3, Rt */
assign o_rrq_rt3_we_mask = t_we[3].r[1].o_rrq_we_mask;
assign o_rrq_rt3_we_wr = t_we[3].r[1].o_rrq_we_wr;
assign t_we[3].r[1].i_rrq_we_rdy = i_rrq_rt3_we_rdy;
/* Thread 4, Rs */
assign o_rrq_rs4_we_mask = t_we[4].r[0].o_rrq_we_mask;
assign o_rrq_rs4_we_wr = t_we[4].r[0].o_rrq_we_wr;
assign t_we[4].r[0].i_rrq_we_rdy = i_rrq_rs4_we_rdy;
/* Thread 4, Rt */
assign o_rrq_rt4_we_mask = t_we[4].r[1].o_rrq_we_mask;
assign o_rrq_rt4_we_wr = t_we[4].r[1].o_rrq_we_wr;
assign t_we[4].r[1].i_rrq_we_rdy = i_rrq_rt4_we_rdy;
/* Thread 5, Rs */
assign o_rrq_rs5_we_mask = t_we[5].r[0].o_rrq_we_mask;
assign o_rrq_rs5_we_wr = t_we[5].r[0].o_rrq_we_wr;
assign t_we[5].r[0].i_rrq_we_rdy = i_rrq_rs5_we_rdy;
/* Thread 5, Rt */
assign o_rrq_rt5_we_mask = t_we[5].r[1].o_rrq_we_mask;
assign o_rrq_rt5_we_wr = t_we[5].r[1].o_rrq_we_wr;
assign t_we[5].r[1].i_rrq_we_rdy = i_rrq_rt5_we_rdy;
/* Thread 6, Rs */
assign o_rrq_rs6_we_mask = t_we[6].r[0].o_rrq_we_mask;
assign o_rrq_rs6_we_wr = t_we[6].r[0].o_rrq_we_wr;
assign t_we[6].r[0].i_rrq_we_rdy = i_rrq_rs6_we_rdy;
/* Thread 6, Rt */
assign o_rrq_rt6_we_mask = t_we[6].r[1].o_rrq_we_mask;
assign o_rrq_rt6_we_wr = t_we[6].r[1].o_rrq_we_wr;
assign t_we[6].r[1].i_rrq_we_rdy = i_rrq_rt6_we_rdy;
/* Thread 7, Rs */
assign o_rrq_rs7_we_mask = t_we[7].r[0].o_rrq_we_mask;
assign o_rrq_rs7_we_wr = t_we[7].r[0].o_rrq_we_wr;
assign t_we[7].r[0].i_rrq_we_rdy = i_rrq_rs7_we_rdy;
/* Thread 7, Rt */
assign o_rrq_rt7_we_mask = t_we[7].r[1].o_rrq_we_mask;
assign o_rrq_rt7_we_wr = t_we[7].r[1].o_rrq_we_wr;
assign t_we[7].r[1].i_rrq_we_rdy = i_rrq_rt7_we_rdy;



endmodule /* vxe_vpu_prod_eu_rq_disp */
