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
 * VxE VPU responses distributor unit
 */


/* Responses distributor unit */
module vxe_vpu_prod_eu_rs_dist #(
	parameter IN_WE_DEPTH_POW2 = 2,	/* Incoming write enable FIFOs depth (2^IN_WE_DEPTH_POW2) */
	parameter IN_RS_DEPTH_POW2 = 3,	/* Incoming response FIFO depth (2^IN_RS_DEPTH_POW2) */
	parameter OUT_OP_DEPTH_POW2 = 2	/* Outgoing operand FIFOs depth (2^OUT_OP_DEPTH_POW2) */
)
(
	clk,
	nrst,
	/* Control interface */
	i_err_flush,
	o_busy,
	/* LSU interface */
	i_rrs_vld,
	o_rrs_rd,
	i_rrs_th,
	i_rrs_arg,
	i_rrs_data,
	/* Write enable FIFO interface */
	i_rrs_rs0_we_mask,
	o_rrs_rs0_we_rd,
	i_rrs_rs0_we_vld,
	i_rrs_rt0_we_mask,
	o_rrs_rt0_we_rd,
	i_rrs_rt0_we_vld,
	i_rrs_rs1_we_mask,
	o_rrs_rs1_we_rd,
	i_rrs_rs1_we_vld,
	i_rrs_rt1_we_mask,
	o_rrs_rt1_we_rd,
	i_rrs_rt1_we_vld,
	i_rrs_rs2_we_mask,
	o_rrs_rs2_we_rd,
	i_rrs_rs2_we_vld,
	i_rrs_rt2_we_mask,
	o_rrs_rt2_we_rd,
	i_rrs_rt2_we_vld,
	i_rrs_rs3_we_mask,
	o_rrs_rs3_we_rd,
	i_rrs_rs3_we_vld,
	i_rrs_rt3_we_mask,
	o_rrs_rt3_we_rd,
	i_rrs_rt3_we_vld,
	i_rrs_rs4_we_mask,
	o_rrs_rs4_we_rd,
	i_rrs_rs4_we_vld,
	i_rrs_rt4_we_mask,
	o_rrs_rt4_we_rd,
	i_rrs_rt4_we_vld,
	i_rrs_rs5_we_mask,
	o_rrs_rs5_we_rd,
	i_rrs_rs5_we_vld,
	i_rrs_rt5_we_mask,
	o_rrs_rt5_we_rd,
	i_rrs_rt5_we_vld,
	i_rrs_rs6_we_mask,
	o_rrs_rs6_we_rd,
	i_rrs_rs6_we_vld,
	i_rrs_rt6_we_mask,
	o_rrs_rt6_we_rd,
	i_rrs_rt6_we_vld,
	i_rrs_rs7_we_mask,
	o_rrs_rs7_we_rd,
	i_rrs_rs7_we_vld,
	i_rrs_rt7_we_mask,
	o_rrs_rt7_we_rd,
	i_rrs_rt7_we_vld,
	/* Operand FIFO interface */
	o_f21_rs0_opd_data,
	o_f21_rs0_opd_wr,
	i_f21_rs0_opd_rdy,
	o_f21_rt0_opd_data,
	o_f21_rt0_opd_wr,
	i_f21_rt0_opd_rdy,
	o_f21_rs1_opd_data,
	o_f21_rs1_opd_wr,
	i_f21_rs1_opd_rdy,
	o_f21_rt1_opd_data,
	o_f21_rt1_opd_wr,
	i_f21_rt1_opd_rdy,
	o_f21_rs2_opd_data,
	o_f21_rs2_opd_wr,
	i_f21_rs2_opd_rdy,
	o_f21_rt2_opd_data,
	o_f21_rt2_opd_wr,
	i_f21_rt2_opd_rdy,
	o_f21_rs3_opd_data,
	o_f21_rs3_opd_wr,
	i_f21_rs3_opd_rdy,
	o_f21_rt3_opd_data,
	o_f21_rt3_opd_wr,
	i_f21_rt3_opd_rdy,
	o_f21_rs4_opd_data,
	o_f21_rs4_opd_wr,
	i_f21_rs4_opd_rdy,
	o_f21_rt4_opd_data,
	o_f21_rt4_opd_wr,
	i_f21_rt4_opd_rdy,
	o_f21_rs5_opd_data,
	o_f21_rs5_opd_wr,
	i_f21_rs5_opd_rdy,
	o_f21_rt5_opd_data,
	o_f21_rt5_opd_wr,
	i_f21_rt5_opd_rdy,
	o_f21_rs6_opd_data,
	o_f21_rs6_opd_wr,
	i_f21_rs6_opd_rdy,
	o_f21_rt6_opd_data,
	o_f21_rt6_opd_wr,
	i_f21_rt6_opd_rdy,
	o_f21_rs7_opd_data,
	o_f21_rs7_opd_wr,
	i_f21_rs7_opd_rdy,
	o_f21_rt7_opd_data,
	o_f21_rt7_opd_wr,
	i_f21_rt7_opd_rdy
);
/* Response FSM states */
localparam [1:0]	FSM_RS_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RS_RECV = 2'b01;	/* Receive responses */
localparam [1:0]	FSM_RS_STLL = 2'b10;	/* Stall */
/* Write enable FSM states */
localparam [1:0]	FSM_WE_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_WE_RECV = 2'b01;	/* Receive WE data */
localparam [1:0]	FSM_WE_STLL = 2'b10;	/* Stall */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Control interface */
input wire		i_err_flush;
output wire		o_busy;
/* LSU interface */
input wire		i_rrs_vld;
output reg		o_rrs_rd;
input wire [2:0]	i_rrs_th;
input wire		i_rrs_arg;
input wire [63:0]	i_rrs_data;
/* Write enable FIFO interface */
input wire [1:0]	i_rrs_rs0_we_mask;
output wire		o_rrs_rs0_we_rd;
input wire		i_rrs_rs0_we_vld;
input wire [1:0]	i_rrs_rt0_we_mask;
output wire		o_rrs_rt0_we_rd;
input wire		i_rrs_rt0_we_vld;
input wire [1:0]	i_rrs_rs1_we_mask;
output wire		o_rrs_rs1_we_rd;
input wire		i_rrs_rs1_we_vld;
input wire [1:0]	i_rrs_rt1_we_mask;
output wire		o_rrs_rt1_we_rd;
input wire		i_rrs_rt1_we_vld;
input wire [1:0]	i_rrs_rs2_we_mask;
output wire		o_rrs_rs2_we_rd;
input wire		i_rrs_rs2_we_vld;
input wire [1:0]	i_rrs_rt2_we_mask;
output wire		o_rrs_rt2_we_rd;
input wire		i_rrs_rt2_we_vld;
input wire [1:0]	i_rrs_rs3_we_mask;
output wire		o_rrs_rs3_we_rd;
input wire		i_rrs_rs3_we_vld;
input wire [1:0]	i_rrs_rt3_we_mask;
output wire		o_rrs_rt3_we_rd;
input wire		i_rrs_rt3_we_vld;
input wire [1:0]	i_rrs_rs4_we_mask;
output wire		o_rrs_rs4_we_rd;
input wire		i_rrs_rs4_we_vld;
input wire [1:0]	i_rrs_rt4_we_mask;
output wire		o_rrs_rt4_we_rd;
input wire		i_rrs_rt4_we_vld;
input wire [1:0]	i_rrs_rs5_we_mask;
output wire		o_rrs_rs5_we_rd;
input wire		i_rrs_rs5_we_vld;
input wire [1:0]	i_rrs_rt5_we_mask;
output wire		o_rrs_rt5_we_rd;
input wire		i_rrs_rt5_we_vld;
input wire [1:0]	i_rrs_rs6_we_mask;
output wire		o_rrs_rs6_we_rd;
input wire		i_rrs_rs6_we_vld;
input wire [1:0]	i_rrs_rt6_we_mask;
output wire		o_rrs_rt6_we_rd;
input wire		i_rrs_rt6_we_vld;
input wire [1:0]	i_rrs_rs7_we_mask;
output wire		o_rrs_rs7_we_rd;
input wire		i_rrs_rs7_we_vld;
input wire [1:0]	i_rrs_rt7_we_mask;
output wire		o_rrs_rt7_we_rd;
input wire		i_rrs_rt7_we_vld;
/* Operand FIFO interface */
output wire [63:0]	o_f21_rs0_opd_data;
output wire [1:0]	o_f21_rs0_opd_wr;
input wire		i_f21_rs0_opd_rdy;
output wire [63:0]	o_f21_rt0_opd_data;
output wire [1:0]	o_f21_rt0_opd_wr;
input wire		i_f21_rt0_opd_rdy;
output wire [63:0]	o_f21_rs1_opd_data;
output wire [1:0]	o_f21_rs1_opd_wr;
input wire		i_f21_rs1_opd_rdy;
output wire [63:0]	o_f21_rt1_opd_data;
output wire [1:0]	o_f21_rt1_opd_wr;
input wire		i_f21_rt1_opd_rdy;
output wire [63:0]	o_f21_rs2_opd_data;
output wire [1:0]	o_f21_rs2_opd_wr;
input wire		i_f21_rs2_opd_rdy;
output wire [63:0]	o_f21_rt2_opd_data;
output wire [1:0]	o_f21_rt2_opd_wr;
input wire		i_f21_rt2_opd_rdy;
output wire [63:0]	o_f21_rs3_opd_data;
output wire [1:0]	o_f21_rs3_opd_wr;
input wire		i_f21_rs3_opd_rdy;
output wire [63:0]	o_f21_rt3_opd_data;
output wire [1:0]	o_f21_rt3_opd_wr;
input wire		i_f21_rt3_opd_rdy;
output wire [63:0]	o_f21_rs4_opd_data;
output wire [1:0]	o_f21_rs4_opd_wr;
input wire		i_f21_rs4_opd_rdy;
output wire [63:0]	o_f21_rt4_opd_data;
output wire [1:0]	o_f21_rt4_opd_wr;
input wire		i_f21_rt4_opd_rdy;
output wire [63:0]	o_f21_rs5_opd_data;
output wire [1:0]	o_f21_rs5_opd_wr;
input wire		i_f21_rs5_opd_rdy;
output wire [63:0]	o_f21_rt5_opd_data;
output wire [1:0]	o_f21_rt5_opd_wr;
input wire		i_f21_rt5_opd_rdy;
output wire [63:0]	o_f21_rs6_opd_data;
output wire [1:0]	o_f21_rs6_opd_wr;
input wire		i_f21_rs6_opd_rdy;
output wire [63:0]	o_f21_rt6_opd_data;
output wire [1:0]	o_f21_rt6_opd_wr;
input wire		i_f21_rt6_opd_rdy;
output wire [63:0]	o_f21_rs7_opd_data;
output wire [1:0]	o_f21_rs7_opd_wr;
input wire		i_f21_rs7_opd_rdy;
output wire [63:0]	o_f21_rt7_opd_data;
output wire [1:0]	o_f21_rt7_opd_wr;
input wire		i_f21_rt7_opd_rdy;


genvar i, j;	/* Generator block vars */


/* At least one word enable FIFO is not empty */
wire in_we_fifo_busy = !t_we[0].r[0].we_fifo_empty || !t_we[0].r[1].we_fifo_empty ||
		!t_we[1].r[0].we_fifo_empty || !t_we[1].r[1].we_fifo_empty ||
		!t_we[2].r[0].we_fifo_empty || !t_we[2].r[1].we_fifo_empty ||
		!t_we[3].r[0].we_fifo_empty || !t_we[3].r[1].we_fifo_empty ||
		!t_we[4].r[0].we_fifo_empty || !t_we[4].r[1].we_fifo_empty ||
		!t_we[5].r[0].we_fifo_empty || !t_we[5].r[1].we_fifo_empty ||
		!t_we[6].r[0].we_fifo_empty || !t_we[6].r[1].we_fifo_empty ||
		!t_we[7].r[0].we_fifo_empty || !t_we[7].r[1].we_fifo_empty;

/* At least one word enable FSM is busy */
wire in_we_fsm_busy = t_we[0].r[0].fsm_we_busy || t_we[0].r[1].fsm_we_busy ||
	t_we[1].r[0].fsm_we_busy || t_we[1].r[1].fsm_we_busy ||
	t_we[2].r[0].fsm_we_busy || t_we[2].r[1].fsm_we_busy ||
	t_we[3].r[0].fsm_we_busy || t_we[3].r[1].fsm_we_busy ||
	t_we[4].r[0].fsm_we_busy || t_we[4].r[1].fsm_we_busy ||
	t_we[5].r[0].fsm_we_busy || t_we[5].r[1].fsm_we_busy ||
	t_we[6].r[0].fsm_we_busy || t_we[6].r[1].fsm_we_busy ||
	t_we[7].r[0].fsm_we_busy || t_we[7].r[1].fsm_we_busy;

/* At least one operand FIFO is not empty */
wire out_op_fifo_busy = !t_op[0].r[0].op_fifo_empty || !t_op[0].r[1].op_fifo_empty ||
	!t_op[1].r[0].op_fifo_empty || !t_op[1].r[1].op_fifo_empty ||
	!t_op[2].r[0].op_fifo_empty || !t_op[2].r[1].op_fifo_empty ||
	!t_op[3].r[0].op_fifo_empty || !t_op[3].r[1].op_fifo_empty ||
	!t_op[4].r[0].op_fifo_empty || !t_op[4].r[1].op_fifo_empty ||
	!t_op[5].r[0].op_fifo_empty || !t_op[5].r[1].op_fifo_empty ||
	!t_op[6].r[0].op_fifo_empty || !t_op[6].r[1].op_fifo_empty ||
	!t_op[7].r[0].op_fifo_empty || !t_op[7].r[1].op_fifo_empty;

/* At least one operand FSM is busy */
wire out_op_fsm_busy = t_op[0].r[0].fsm_op_busy || t_op[0].r[1].fsm_op_busy ||
	t_op[1].r[0].fsm_op_busy || t_op[1].r[1].fsm_op_busy ||
	t_op[2].r[0].fsm_op_busy || t_op[2].r[1].fsm_op_busy ||
	t_op[3].r[0].fsm_op_busy || t_op[3].r[1].fsm_op_busy ||
	t_op[4].r[0].fsm_op_busy || t_op[4].r[1].fsm_op_busy ||
	t_op[5].r[0].fsm_op_busy || t_op[5].r[1].fsm_op_busy ||
	t_op[6].r[0].fsm_op_busy || t_op[6].r[1].fsm_op_busy ||
	t_op[7].r[0].fsm_op_busy || t_op[7].r[1].fsm_op_busy;


/* Busy state */
assign o_busy = in_we_fifo_busy || in_we_fsm_busy ||
	out_op_fifo_busy || out_op_fsm_busy ||
	!rs_fifo_empty || fsm_rs_busy;



/*************** Generate per thread, per argument WE read FSMs ***************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t_we
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		/* Block inputs/outputs */
		wire [1:0]	i_rrs_we_mask;
		reg		o_rrs_we_rd;
		wire		i_rrs_we_vld;

		/*** Word enable FIFO ***/
		reg [1:0]			we_fifo[0:2**IN_WE_DEPTH_POW2-1];
		reg [IN_WE_DEPTH_POW2:0]	we_fifo_rp;	/* Read pointer */
		reg [IN_WE_DEPTH_POW2:0]	we_fifo_wp;	/* Write pointer */

		/* Previous FIFO read pointer */
		wire [IN_WE_DEPTH_POW2:0]	we_fifo_pre_rp = we_fifo_rp - 1'b1;

		/* FIFO states */
		wire we_fifo_empty = (we_fifo_rp[IN_WE_DEPTH_POW2] == we_fifo_wp[IN_WE_DEPTH_POW2]) &&
			(we_fifo_rp[IN_WE_DEPTH_POW2-1:0] == we_fifo_wp[IN_WE_DEPTH_POW2-1:0]);

		wire we_fifo_full = (we_fifo_rp[IN_WE_DEPTH_POW2] != we_fifo_wp[IN_WE_DEPTH_POW2]) &&
			(we_fifo_rp[IN_WE_DEPTH_POW2-1:0] == we_fifo_wp[IN_WE_DEPTH_POW2-1:0]);

		wire we_fifo_pre_full = (we_fifo_pre_rp[IN_WE_DEPTH_POW2] != we_fifo_wp[IN_WE_DEPTH_POW2]) &&
			(we_fifo_pre_rp[IN_WE_DEPTH_POW2-1:0] == we_fifo_wp[IN_WE_DEPTH_POW2-1:0]);

		/* FIFO stall */
		wire we_fifo_stall = we_fifo_full || we_fifo_pre_full;


		/* WE FSM */
		wire fsm_we_busy = (fsm_we != FSM_WE_IDLE);
		reg [1:0] fsm_we;

		always @(posedge clk or negedge nrst)
		begin
			if(!nrst)
			begin
				we_fifo_wp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
				o_rrs_we_rd <= 1'b0;
				fsm_we <= FSM_WE_IDLE;
			end
			else if(fsm_we == FSM_WE_RECV)
			begin
				if(i_rrs_we_vld)
				begin
					we_fifo[we_fifo_wp[IN_WE_DEPTH_POW2-1:0]] <= i_rrs_we_mask;
					we_fifo_wp <= we_fifo_wp + 1'b1;
				end

				if(we_fifo_stall)
				begin
					o_rrs_we_rd <= 1'b0;
					fsm_we <= FSM_WE_STLL;
				end

				if(!i_rrs_we_vld)
				begin
					o_rrs_we_rd <= 1'b0;
					fsm_we <= FSM_WE_IDLE;
				end
			end
			else if(fsm_we == FSM_WE_STLL)
			begin
				if(!we_fifo_stall)
				begin
					o_rrs_we_rd <= 1'b1;
					fsm_we <= FSM_WE_RECV;
				end
			end
			else	/* FSM_WE_IDLE */
			begin
				if(i_rrs_we_vld)
				begin
					o_rrs_we_rd <= 1'b1;
					fsm_we <= FSM_WE_RECV;
				end
			end
		end
	end	/* for(j, ...) */
end	/* for(i, ...) */

endgenerate


/*** Connect generated blocks ***/

/* Thread 0, Rs */
assign t_we[0].r[0].i_rrs_we_mask = i_rrs_rs0_we_mask;
assign o_rrs_rs0_we_rd = t_we[0].r[0].o_rrs_we_rd;
assign t_we[0].r[0].i_rrs_we_vld = i_rrs_rs0_we_vld;
/* Thread 0, Rt */
assign t_we[0].r[1].i_rrs_we_mask = i_rrs_rt0_we_mask;
assign o_rrs_rt0_we_rd = t_we[0].r[1].o_rrs_we_rd;
assign t_we[0].r[1].i_rrs_we_vld = i_rrs_rt0_we_vld;
/* Thread 1, Rs */
assign t_we[1].r[0].i_rrs_we_mask = i_rrs_rs1_we_mask;
assign o_rrs_rs1_we_rd = t_we[1].r[0].o_rrs_we_rd;
assign t_we[1].r[0].i_rrs_we_vld = i_rrs_rs1_we_vld;
/* Thread 1, Rt */
assign t_we[1].r[1].i_rrs_we_mask = i_rrs_rt1_we_mask;
assign o_rrs_rt1_we_rd = t_we[1].r[1].o_rrs_we_rd;
assign t_we[1].r[1].i_rrs_we_vld = i_rrs_rt1_we_vld;
/* Thread 2, Rs */
assign t_we[2].r[0].i_rrs_we_mask = i_rrs_rs2_we_mask;
assign o_rrs_rs2_we_rd = t_we[2].r[0].o_rrs_we_rd;
assign t_we[2].r[0].i_rrs_we_vld = i_rrs_rs2_we_vld;
/* Thread 2, Rt */
assign t_we[2].r[1].i_rrs_we_mask = i_rrs_rt2_we_mask;
assign o_rrs_rt2_we_rd = t_we[2].r[1].o_rrs_we_rd;
assign t_we[2].r[1].i_rrs_we_vld = i_rrs_rt2_we_vld;
/* Thread 3, Rs */
assign t_we[3].r[0].i_rrs_we_mask = i_rrs_rs3_we_mask;
assign o_rrs_rs3_we_rd = t_we[3].r[0].o_rrs_we_rd;
assign t_we[3].r[0].i_rrs_we_vld = i_rrs_rs3_we_vld;
/* Thread 3, Rt */
assign t_we[3].r[1].i_rrs_we_mask = i_rrs_rt3_we_mask;
assign o_rrs_rt3_we_rd = t_we[3].r[1].o_rrs_we_rd;
assign t_we[3].r[1].i_rrs_we_vld = i_rrs_rt3_we_vld;
/* Thread 4, Rs */
assign t_we[4].r[0].i_rrs_we_mask = i_rrs_rs4_we_mask;
assign o_rrs_rs4_we_rd = t_we[4].r[0].o_rrs_we_rd;
assign t_we[4].r[0].i_rrs_we_vld = i_rrs_rs4_we_vld;
/* Thread 4, Rt */
assign t_we[4].r[1].i_rrs_we_mask = i_rrs_rt4_we_mask;
assign o_rrs_rt4_we_rd = t_we[4].r[1].o_rrs_we_rd;
assign t_we[4].r[1].i_rrs_we_vld = i_rrs_rt4_we_vld;
/* Thread 5, Rs */
assign t_we[5].r[0].i_rrs_we_mask = i_rrs_rs5_we_mask;
assign o_rrs_rs5_we_rd = t_we[5].r[0].o_rrs_we_rd;
assign t_we[5].r[0].i_rrs_we_vld = i_rrs_rs5_we_vld;
/* Thread 5, Rt */
assign t_we[5].r[1].i_rrs_we_mask = i_rrs_rt5_we_mask;
assign o_rrs_rt5_we_rd = t_we[5].r[1].o_rrs_we_rd;
assign t_we[5].r[1].i_rrs_we_vld = i_rrs_rt5_we_vld;
/* Thread 6, Rs */
assign t_we[6].r[0].i_rrs_we_mask = i_rrs_rs6_we_mask;
assign o_rrs_rs6_we_rd = t_we[6].r[0].o_rrs_we_rd;
assign t_we[6].r[0].i_rrs_we_vld = i_rrs_rs6_we_vld;
/* Thread 6, Rt */
assign t_we[6].r[1].i_rrs_we_mask = i_rrs_rt6_we_mask;
assign o_rrs_rt6_we_rd = t_we[6].r[1].o_rrs_we_rd;
assign t_we[6].r[1].i_rrs_we_vld = i_rrs_rt6_we_vld;
/* Thread 7, Rs */
assign t_we[7].r[0].i_rrs_we_mask = i_rrs_rs7_we_mask;
assign o_rrs_rs7_we_rd = t_we[7].r[0].o_rrs_we_rd;
assign t_we[7].r[0].i_rrs_we_vld = i_rrs_rs7_we_vld;
/* Thread 7, Rt */
assign t_we[7].r[1].i_rrs_we_mask = i_rrs_rt7_we_mask;
assign o_rrs_rt7_we_rd = t_we[7].r[1].o_rrs_we_rd;
assign t_we[7].r[1].i_rrs_we_vld = i_rrs_rt7_we_vld;



/******************** Responses receiving FIFO and FSM ************************/


/*** Received response FIFO ***/
reg [2:0]			rs_th_fifo[0:2**IN_RS_DEPTH_POW2-1];
reg				rs_arg_fifo[0:2**IN_RS_DEPTH_POW2-1];
reg [63:0]			rs_data_fifo[0:2**IN_RS_DEPTH_POW2-1];
reg [IN_RS_DEPTH_POW2:0]	rs_fifo_rp;	/* Read pointer */
reg [IN_RS_DEPTH_POW2:0]	rs_fifo_wp;	/* Write pointer */

/* Previous FIFO read pointer */
wire [IN_RS_DEPTH_POW2:0]	rs_fifo_pre_rp = rs_fifo_rp - 1'b1;

/* FIFO states */
wire rs_fifo_empty = (rs_fifo_rp[IN_RS_DEPTH_POW2] == rs_fifo_wp[IN_RS_DEPTH_POW2]) &&
	(rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] == rs_fifo_wp[IN_RS_DEPTH_POW2-1:0]);

wire rs_fifo_full = (rs_fifo_rp[IN_RS_DEPTH_POW2] != rs_fifo_wp[IN_RS_DEPTH_POW2]) &&
	(rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] == rs_fifo_wp[IN_RS_DEPTH_POW2-1:0]);

wire rs_fifo_pre_full = (rs_fifo_pre_rp[IN_RS_DEPTH_POW2] != rs_fifo_wp[IN_RS_DEPTH_POW2]) &&
	(rs_fifo_pre_rp[IN_RS_DEPTH_POW2-1:0] == rs_fifo_wp[IN_RS_DEPTH_POW2-1:0]);

/* FIFO stall */
wire rs_fifo_stall = rs_fifo_full || rs_fifo_pre_full;


/* Response receive FSM */
wire fsm_rs_busy = (fsm_rs != FSM_RS_IDLE);
reg [1:0] fsm_rs;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rs_fifo_wp <= {(IN_RS_DEPTH_POW2+1){1'b0}};
		o_rrs_rd <= 1'b0;
		fsm_rs <= FSM_RS_IDLE;
	end
	else if(fsm_rs == FSM_RS_RECV)
	begin
		if(i_rrs_vld)
		begin
			rs_th_fifo[rs_fifo_wp[IN_RS_DEPTH_POW2-1:0]] <= i_rrs_th;
			rs_arg_fifo[rs_fifo_wp[IN_RS_DEPTH_POW2-1:0]] <= i_rrs_arg;
			rs_data_fifo[rs_fifo_wp[IN_RS_DEPTH_POW2-1:0]] <= i_rrs_data;
			rs_fifo_wp <= rs_fifo_wp + 1'b1;
		end

		if(rs_fifo_stall)
		begin
			o_rrs_rd <= 1'b0;
			fsm_rs <= FSM_RS_STLL;
		end

		if(!i_rrs_vld)
		begin
			o_rrs_rd <= 1'b0;
			fsm_rs <= FSM_RS_IDLE;
		end
	end
	else if(fsm_rs == FSM_RS_STLL)
	begin
		if(!rs_fifo_stall)
		begin
			o_rrs_rd <= 1'b1;
			fsm_rs <= FSM_RS_RECV;
		end
	end
	else	/* FSM_RS_IDLE */
	begin
		if(i_rrs_vld)
		begin
			o_rrs_rd <= 1'b1;
			fsm_rs <= FSM_RS_RECV;
		end
	end
end



/********************** Operands distribution logic ***************************/

reg q_err_flush;	/* Drop incoming data on error state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		q_err_flush <= 1'b0;
		rs_fifo_rp <= {(IN_RS_DEPTH_POW2+1){1'b0}};
		t_we[0].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[0].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[1].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[1].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[2].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[2].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[3].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[3].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[4].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[4].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[5].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[5].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[6].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[6].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[7].r[0].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_we[7].r[1].we_fifo_rp <= {(IN_WE_DEPTH_POW2+1){1'b0}};
		t_op[0].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[0].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[1].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[1].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[2].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[2].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[3].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[3].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[4].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[4].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[5].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[5].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[6].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[6].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[7].r[0].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
		t_op[7].r[1].op_fifo_wp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
	end
	else if(i_err_flush || q_err_flush)
	begin
		/* Flush incoming response and WE data on error */
		q_err_flush <= i_err_flush | q_err_flush;

		rs_fifo_rp <= rs_fifo_wp;
		t_we[0].r[0].we_fifo_rp <= t_we[0].r[0].we_fifo_wp;
		t_we[0].r[1].we_fifo_rp <= t_we[0].r[1].we_fifo_wp;
		t_we[1].r[0].we_fifo_rp <= t_we[1].r[0].we_fifo_wp;
		t_we[1].r[1].we_fifo_rp <= t_we[1].r[1].we_fifo_wp;
		t_we[2].r[0].we_fifo_rp <= t_we[2].r[0].we_fifo_wp;
		t_we[2].r[1].we_fifo_rp <= t_we[2].r[1].we_fifo_wp;
		t_we[3].r[0].we_fifo_rp <= t_we[3].r[0].we_fifo_wp;
		t_we[3].r[1].we_fifo_rp <= t_we[3].r[1].we_fifo_wp;
		t_we[4].r[0].we_fifo_rp <= t_we[4].r[0].we_fifo_wp;
		t_we[4].r[1].we_fifo_rp <= t_we[4].r[1].we_fifo_wp;
		t_we[5].r[0].we_fifo_rp <= t_we[5].r[0].we_fifo_wp;
		t_we[5].r[1].we_fifo_rp <= t_we[5].r[1].we_fifo_wp;
		t_we[6].r[0].we_fifo_rp <= t_we[6].r[0].we_fifo_wp;
		t_we[6].r[1].we_fifo_rp <= t_we[6].r[1].we_fifo_wp;
		t_we[7].r[0].we_fifo_rp <= t_we[7].r[0].we_fifo_wp;
		t_we[7].r[1].we_fifo_rp <= t_we[7].r[1].we_fifo_wp;

		if(!(in_we_fifo_busy || in_we_fsm_busy || !rs_fifo_empty || fsm_rs_busy))
			q_err_flush <= 1'b0;
	end
	else
	case({ rs_fifo_empty, rs_th_fifo[rs_fifo_rp[IN_RS_DEPTH_POW2-1:0]],
		rs_arg_fifo[rs_fifo_rp[IN_RS_DEPTH_POW2-1:0]] })
	/* Thread 0, Rs */
	5'b0_000_0: if(!t_we[0].r[0].we_fifo_empty && !t_op[0].r[0].op_fifo_stall)
	begin
		t_op[0].r[0].op_fifo[ t_op[0].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[0].r[0].op_w_fifo[ t_op[0].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[0].r[0].we_fifo[ t_we[0].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[0].r[0].op_fifo_wp <= t_op[0].r[0].op_fifo_wp + 1'b1;
		t_we[0].r[0].we_fifo_rp <= t_we[0].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 0, Rt */
	5'b0_000_1: if(!t_we[0].r[1].we_fifo_empty && !t_op[0].r[1].op_fifo_stall)
	begin
		t_op[0].r[1].op_fifo[ t_op[0].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[0].r[1].op_w_fifo[ t_op[0].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[0].r[1].we_fifo[ t_we[0].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[0].r[1].op_fifo_wp <= t_op[0].r[1].op_fifo_wp + 1'b1;
		t_we[0].r[1].we_fifo_rp <= t_we[0].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 1, Rs */
	5'b0_001_0: if(!t_we[1].r[0].we_fifo_empty && !t_op[1].r[0].op_fifo_stall)
	begin
		t_op[1].r[0].op_fifo[ t_op[1].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[1].r[0].op_w_fifo[ t_op[1].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[1].r[0].we_fifo[ t_we[1].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[1].r[0].op_fifo_wp <= t_op[1].r[0].op_fifo_wp + 1'b1;
		t_we[1].r[0].we_fifo_rp <= t_we[1].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 1, Rt */
	5'b0_001_1: if(!t_we[1].r[1].we_fifo_empty && !t_op[1].r[1].op_fifo_stall)
	begin
		t_op[1].r[1].op_fifo[ t_op[1].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[1].r[1].op_w_fifo[ t_op[1].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[1].r[1].we_fifo[ t_we[1].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[1].r[1].op_fifo_wp <= t_op[1].r[1].op_fifo_wp + 1'b1;
		t_we[1].r[1].we_fifo_rp <= t_we[1].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 2, Rs */
	5'b0_010_0: if(!t_we[2].r[0].we_fifo_empty && !t_op[2].r[0].op_fifo_stall)
	begin
		t_op[2].r[0].op_fifo[ t_op[2].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[2].r[0].op_w_fifo[ t_op[2].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[2].r[0].we_fifo[ t_we[2].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[2].r[0].op_fifo_wp <= t_op[2].r[0].op_fifo_wp + 1'b1;
		t_we[2].r[0].we_fifo_rp <= t_we[2].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 2, Rt */
	5'b0_010_1: if(!t_we[2].r[1].we_fifo_empty && !t_op[2].r[1].op_fifo_stall)
	begin
		t_op[2].r[1].op_fifo[ t_op[2].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[2].r[1].op_w_fifo[ t_op[2].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[2].r[1].we_fifo[ t_we[2].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[2].r[1].op_fifo_wp <= t_op[2].r[1].op_fifo_wp + 1'b1;
		t_we[2].r[1].we_fifo_rp <= t_we[2].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 3, Rs */
	5'b0_011_0: if(!t_we[3].r[0].we_fifo_empty && !t_op[3].r[0].op_fifo_stall)
	begin
		t_op[3].r[0].op_fifo[ t_op[3].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[3].r[0].op_w_fifo[ t_op[3].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[3].r[0].we_fifo[ t_we[3].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[3].r[0].op_fifo_wp <= t_op[3].r[0].op_fifo_wp + 1'b1;
		t_we[3].r[0].we_fifo_rp <= t_we[3].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 3, Rt */
	5'b0_011_1: if(!t_we[3].r[1].we_fifo_empty && !t_op[3].r[1].op_fifo_stall)
	begin
		t_op[3].r[1].op_fifo[ t_op[3].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[3].r[1].op_w_fifo[ t_op[3].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[3].r[1].we_fifo[ t_we[3].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[3].r[1].op_fifo_wp <= t_op[3].r[1].op_fifo_wp + 1'b1;
		t_we[3].r[1].we_fifo_rp <= t_we[3].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 4, Rs */
	5'b0_100_0: if(!t_we[4].r[0].we_fifo_empty && !t_op[4].r[0].op_fifo_stall)
	begin
		t_op[4].r[0].op_fifo[ t_op[4].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[4].r[0].op_w_fifo[ t_op[4].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[4].r[0].we_fifo[ t_we[4].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[4].r[0].op_fifo_wp <= t_op[4].r[0].op_fifo_wp + 1'b1;
		t_we[4].r[0].we_fifo_rp <= t_we[4].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 4, Rt */
	5'b0_100_1: if(!t_we[4].r[1].we_fifo_empty && !t_op[4].r[1].op_fifo_stall)
	begin
		t_op[4].r[1].op_fifo[ t_op[4].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[4].r[1].op_w_fifo[ t_op[4].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[4].r[1].we_fifo[ t_we[4].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[4].r[1].op_fifo_wp <= t_op[4].r[1].op_fifo_wp + 1'b1;
		t_we[4].r[1].we_fifo_rp <= t_we[4].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 5, Rs */
	5'b0_101_0: if(!t_we[5].r[0].we_fifo_empty && !t_op[5].r[0].op_fifo_stall)
	begin
		t_op[5].r[0].op_fifo[ t_op[5].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[5].r[0].op_w_fifo[ t_op[5].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[5].r[0].we_fifo[ t_we[5].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[5].r[0].op_fifo_wp <= t_op[5].r[0].op_fifo_wp + 1'b1;
		t_we[5].r[0].we_fifo_rp <= t_we[5].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 5, Rt */
	5'b0_101_1: if(!t_we[5].r[1].we_fifo_empty && !t_op[5].r[1].op_fifo_stall)
	begin
		t_op[5].r[1].op_fifo[ t_op[5].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[5].r[1].op_w_fifo[ t_op[5].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[5].r[1].we_fifo[ t_we[5].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[5].r[1].op_fifo_wp <= t_op[5].r[1].op_fifo_wp + 1'b1;
		t_we[5].r[1].we_fifo_rp <= t_we[5].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 6, Rs */
	5'b0_110_0: if(!t_we[6].r[0].we_fifo_empty && !t_op[6].r[0].op_fifo_stall)
	begin
		t_op[6].r[0].op_fifo[ t_op[6].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[6].r[0].op_w_fifo[ t_op[6].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[6].r[0].we_fifo[ t_we[6].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[6].r[0].op_fifo_wp <= t_op[6].r[0].op_fifo_wp + 1'b1;
		t_we[6].r[0].we_fifo_rp <= t_we[6].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 6, Rt */
	5'b0_110_1: if(!t_we[6].r[1].we_fifo_empty && !t_op[6].r[1].op_fifo_stall)
	begin
		t_op[6].r[1].op_fifo[ t_op[6].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[6].r[1].op_w_fifo[ t_op[6].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[6].r[1].we_fifo[ t_we[6].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[6].r[1].op_fifo_wp <= t_op[6].r[1].op_fifo_wp + 1'b1;
		t_we[6].r[1].we_fifo_rp <= t_we[6].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 7, Rs */
	5'b0_111_0: if(!t_we[7].r[0].we_fifo_empty && !t_op[7].r[0].op_fifo_stall)
	begin
		t_op[7].r[0].op_fifo[ t_op[7].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[7].r[0].op_w_fifo[ t_op[7].r[0].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[7].r[0].we_fifo[ t_we[7].r[0].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[7].r[0].op_fifo_wp <= t_op[7].r[0].op_fifo_wp + 1'b1;
		t_we[7].r[0].we_fifo_rp <= t_we[7].r[0].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	/* Thread 7, Rt */
	5'b0_111_1: if(!t_we[7].r[1].we_fifo_empty && !t_op[7].r[1].op_fifo_stall)
	begin
		t_op[7].r[1].op_fifo[ t_op[7].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= rs_data_fifo[ rs_fifo_rp[IN_RS_DEPTH_POW2-1:0] ];

		t_op[7].r[1].op_w_fifo[ t_op[7].r[1].op_fifo_wp[OUT_OP_DEPTH_POW2-1:0] ]
			<= t_we[7].r[1].we_fifo[ t_we[7].r[1].we_fifo_rp[IN_WE_DEPTH_POW2-1:0] ];

		t_op[7].r[1].op_fifo_wp <= t_op[7].r[1].op_fifo_wp + 1'b1;
		t_we[7].r[1].we_fifo_rp <= t_we[7].r[1].we_fifo_rp + 1'b1;
		rs_fifo_rp <= rs_fifo_rp + 1'b1;
	end
	default: ;
	endcase
end



/************ Generate per thread, per argument operand write FSMs ************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t_op
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		/* Block inputs/outputs */
		reg [63:0]	o_f21_opd_data;
		reg [1:0]	o_f21_opd_wr;
		wire		i_f21_opd_rdy;

		/*** Operand FIFO ***/
		reg [63:0]			op_fifo[0:2**OUT_OP_DEPTH_POW2-1];
		reg [1:0]			op_w_fifo[0:2**OUT_OP_DEPTH_POW2-1];
		reg [OUT_OP_DEPTH_POW2:0]	op_fifo_rp;	/* Read pointer */
		reg [OUT_OP_DEPTH_POW2:0]	op_fifo_wp;	/* Write pointer */

		/* Previous FIFO read pointer */
		wire [OUT_OP_DEPTH_POW2:0]	op_fifo_pre_rp = op_fifo_rp - 1'b1;

		/* FIFO states */
		wire op_fifo_empty = (op_fifo_rp[OUT_OP_DEPTH_POW2] == op_fifo_wp[OUT_OP_DEPTH_POW2]) &&
			(op_fifo_rp[OUT_OP_DEPTH_POW2-1:0] == op_fifo_wp[OUT_OP_DEPTH_POW2-1:0]);

		wire op_fifo_full = (op_fifo_rp[OUT_OP_DEPTH_POW2] != op_fifo_wp[OUT_OP_DEPTH_POW2]) &&
			(op_fifo_rp[OUT_OP_DEPTH_POW2-1:0] == op_fifo_wp[OUT_OP_DEPTH_POW2-1:0]);

		wire op_fifo_pre_full = (op_fifo_pre_rp[IN_WE_DEPTH_POW2] != op_fifo_wp[OUT_OP_DEPTH_POW2]) &&
			(op_fifo_pre_rp[OUT_OP_DEPTH_POW2-1:0] == op_fifo_wp[OUT_OP_DEPTH_POW2-1:0]);

		/* FIFO stall */
		wire op_fifo_stall = op_fifo_full || op_fifo_pre_full;


		/* Op FSM */
		wire fsm_op_busy = (fsm_op != 1'b0);
		reg fsm_op;

		always @(posedge clk or negedge nrst)
		begin
			if(!nrst)
			begin
				fsm_op <= 1'b0;
				op_fifo_rp <= {(OUT_OP_DEPTH_POW2+1){1'b0}};
				o_f21_opd_wr <= 2'b00;
			end
			else if(fsm_op == 1'b0)
			begin
				if(!op_fifo_empty)
				begin
					o_f21_opd_wr <= op_w_fifo[op_fifo_rp[OUT_OP_DEPTH_POW2-1:0]];
					o_f21_opd_data <= op_fifo[op_fifo_rp[OUT_OP_DEPTH_POW2-1:0]];
					op_fifo_rp <= op_fifo_rp + 1'b1;
					fsm_op <= 1'b1;
				end
			end
			else if(fsm_op == 1'b1)
			begin
				if(i_f21_opd_rdy && !op_fifo_empty)
				begin
					o_f21_opd_wr <= op_w_fifo[op_fifo_rp[OUT_OP_DEPTH_POW2-1:0]];
					o_f21_opd_data <= op_fifo[op_fifo_rp[OUT_OP_DEPTH_POW2-1:0]];
					op_fifo_rp <= op_fifo_rp + 1'b1;
				end
				else if(i_f21_opd_rdy && op_fifo_empty)
				begin
					fsm_op <= 1'b0;
					o_f21_opd_wr <= 2'b00;
				end
			end
		end
	end	/* for(j, ...) */
end	/* for(i, ...) */

endgenerate


/*** Connect generated blocks ***/

/* Thread 0, Rs */
assign o_f21_rs0_opd_data = t_op[0].r[0].o_f21_opd_data;
assign o_f21_rs0_opd_wr = t_op[0].r[0].o_f21_opd_wr;
assign t_op[0].r[0].i_f21_opd_rdy = i_f21_rs0_opd_rdy;
/* Thread 0, Rt */
assign o_f21_rt0_opd_data = t_op[0].r[1].o_f21_opd_data;
assign o_f21_rt0_opd_wr = t_op[0].r[1].o_f21_opd_wr;
assign t_op[0].r[1].i_f21_opd_rdy = i_f21_rt0_opd_rdy;
/* Thread 1, Rs */
assign o_f21_rs1_opd_data = t_op[1].r[0].o_f21_opd_data;
assign o_f21_rs1_opd_wr = t_op[1].r[0].o_f21_opd_wr;
assign t_op[1].r[0].i_f21_opd_rdy = i_f21_rs1_opd_rdy;
/* Thread 1, Rt */
assign o_f21_rt1_opd_data = t_op[1].r[1].o_f21_opd_data;
assign o_f21_rt1_opd_wr = t_op[1].r[1].o_f21_opd_wr;
assign t_op[1].r[1].i_f21_opd_rdy = i_f21_rt1_opd_rdy;
/* Thread 2, Rs */
assign o_f21_rs2_opd_data = t_op[2].r[0].o_f21_opd_data;
assign o_f21_rs2_opd_wr = t_op[2].r[0].o_f21_opd_wr;
assign t_op[2].r[0].i_f21_opd_rdy = i_f21_rs2_opd_rdy;
/* Thread 2, Rt */
assign o_f21_rt2_opd_data = t_op[2].r[1].o_f21_opd_data;
assign o_f21_rt2_opd_wr = t_op[2].r[1].o_f21_opd_wr;
assign t_op[2].r[1].i_f21_opd_rdy = i_f21_rt2_opd_rdy;
/* Thread 3, Rs */
assign o_f21_rs3_opd_data = t_op[3].r[0].o_f21_opd_data;
assign o_f21_rs3_opd_wr = t_op[3].r[0].o_f21_opd_wr;
assign t_op[3].r[0].i_f21_opd_rdy = i_f21_rs3_opd_rdy;
/* Thread 3, Rt */
assign o_f21_rt3_opd_data = t_op[3].r[1].o_f21_opd_data;
assign o_f21_rt3_opd_wr = t_op[3].r[1].o_f21_opd_wr;
assign t_op[3].r[1].i_f21_opd_rdy = i_f21_rt3_opd_rdy;
/* Thread 4, Rs */
assign o_f21_rs4_opd_data = t_op[4].r[0].o_f21_opd_data;
assign o_f21_rs4_opd_wr = t_op[4].r[0].o_f21_opd_wr;
assign t_op[4].r[0].i_f21_opd_rdy = i_f21_rs4_opd_rdy;
/* Thread 4, Rt */
assign o_f21_rt4_opd_data = t_op[4].r[1].o_f21_opd_data;
assign o_f21_rt4_opd_wr = t_op[4].r[1].o_f21_opd_wr;
assign t_op[4].r[1].i_f21_opd_rdy = i_f21_rt4_opd_rdy;
/* Thread 5, Rs */
assign o_f21_rs5_opd_data = t_op[5].r[0].o_f21_opd_data;
assign o_f21_rs5_opd_wr = t_op[5].r[0].o_f21_opd_wr;
assign t_op[5].r[0].i_f21_opd_rdy = i_f21_rs5_opd_rdy;
/* Thread 5, Rt */
assign o_f21_rt5_opd_data = t_op[5].r[1].o_f21_opd_data;
assign o_f21_rt5_opd_wr = t_op[5].r[1].o_f21_opd_wr;
assign t_op[5].r[1].i_f21_opd_rdy = i_f21_rt5_opd_rdy;
/* Thread 6, Rs */
assign o_f21_rs6_opd_data = t_op[6].r[0].o_f21_opd_data;
assign o_f21_rs6_opd_wr = t_op[6].r[0].o_f21_opd_wr;
assign t_op[6].r[0].i_f21_opd_rdy = i_f21_rs6_opd_rdy;
/* Thread 6, Rt */
assign o_f21_rt6_opd_data = t_op[6].r[1].o_f21_opd_data;
assign o_f21_rt6_opd_wr = t_op[6].r[1].o_f21_opd_wr;
assign t_op[6].r[1].i_f21_opd_rdy = i_f21_rt6_opd_rdy;
/* Thread 7, Rs */
assign o_f21_rs7_opd_data = t_op[7].r[0].o_f21_opd_data;
assign o_f21_rs7_opd_wr = t_op[7].r[0].o_f21_opd_wr;
assign t_op[7].r[0].i_f21_opd_rdy = i_f21_rs7_opd_rdy;
/* Thread 7, Rt */
assign o_f21_rt7_opd_data = t_op[7].r[1].o_f21_opd_data;
assign o_f21_rt7_opd_wr = t_op[7].r[1].o_f21_opd_wr;
assign t_op[7].r[1].i_f21_opd_rdy = i_f21_rt7_opd_rdy;



endmodule /* vxe_vpu_prod_eu_rs_dist */
