/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
 * VxE VPU FMAC scheduler unit
 */


/* FMAC scheduler unit */
module vxe_vpu_prod_eu_fmac #(
	parameter IN_OP_DEPTH_POW2 = 2	/* Incoming operand FIFOs depth (2^IN_OP_DEPTH_POW2) */
)
(
	clk,
	nrst,
	/* Control interface */
	i_err_flush,
	o_busy,
	/* Operand FIFO interface */
	i_rs0_opd_data,
	o_rs0_opd_rd,
	i_rs0_opd_vld,
	i_rt0_opd_data,
	o_rt0_opd_rd,
	i_rt0_opd_vld,
	i_rs1_opd_data,
	o_rs1_opd_rd,
	i_rs1_opd_vld,
	i_rt1_opd_data,
	o_rt1_opd_rd,
	i_rt1_opd_vld,
	i_rs2_opd_data,
	o_rs2_opd_rd,
	i_rs2_opd_vld,
	i_rt2_opd_data,
	o_rt2_opd_rd,
	i_rt2_opd_vld,
	i_rs3_opd_data,
	o_rs3_opd_rd,
	i_rs3_opd_vld,
	i_rt3_opd_data,
	o_rt3_opd_rd,
	i_rt3_opd_vld,
	i_rs4_opd_data,
	o_rs4_opd_rd,
	i_rs4_opd_vld,
	i_rt4_opd_data,
	o_rt4_opd_rd,
	i_rt4_opd_vld,
	i_rs5_opd_data,
	o_rs5_opd_rd,
	i_rs5_opd_vld,
	i_rt5_opd_data,
	o_rt5_opd_rd,
	i_rt5_opd_vld,
	i_rs6_opd_data,
	o_rs6_opd_rd,
	i_rs6_opd_vld,
	i_rt6_opd_data,
	o_rt6_opd_rd,
	i_rt6_opd_vld,
	i_rs7_opd_data,
	o_rs7_opd_rd,
	i_rs7_opd_vld,
	i_rt7_opd_data,
	o_rt7_opd_rd,
	i_rt7_opd_vld,
	/* Register file accumulator values */
	i_th0_acc,
	i_th1_acc,
	i_th2_acc,
	i_th3_acc,
	i_th4_acc,
	i_th5_acc,
	i_th6_acc,
	i_th7_acc,
	/* Register file write interface */
	o_prod_th,
	o_prod_ridx,
	o_prod_wr_en,
	o_prod_data
);
`include "vxe_vpu_regidx_params.vh"
/* Operand receive FSM states */
localparam [1:0]	FSM_OP_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_OP_RECV = 2'b01;	/* Receive operand data */
localparam [1:0]	FSM_OP_STLL = 2'b10;	/* Stall */
/* FMAC dispatch FSM states */
localparam [4:0]	FSM_FMACD_IDLE = 5'b00000;	/* Idle */
localparam [4:0]	FSM_FMACD_THR0 = 5'b00001;	/* Thread 0 */
localparam [4:0]	FSM_FMACD_THR1 = 5'b00011;	/* Thread 1 */
localparam [4:0]	FSM_FMACD_THR2 = 5'b00010;	/* Thread 2 */
localparam [4:0]	FSM_FMACD_THR3 = 5'b00110;	/* Thread 3 */
localparam [4:0]	FSM_FMACD_THR4 = 5'b00100;	/* Thread 4 */
localparam [4:0]	FSM_FMACD_THR5 = 5'b01100;	/* Thread 5 */
localparam [4:0]	FSM_FMACD_THR6 = 5'b01000;	/* Thread 6 */
localparam [4:0]	FSM_FMACD_THR7 = 5'b11000;	/* Thread 7 */
localparam [4:0]	FSM_FMACD_ERRF = 5'b10000;	/* Flush on error */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Control interface */
input wire		i_err_flush;
output wire		o_busy;
/* Operand FIFO interface */
input wire [31:0]	i_rs0_opd_data;
output wire		o_rs0_opd_rd;
input wire		i_rs0_opd_vld;
input wire [31:0]	i_rt0_opd_data;
output wire		o_rt0_opd_rd;
input wire		i_rt0_opd_vld;
input wire [31:0]	i_rs1_opd_data;
output wire		o_rs1_opd_rd;
input wire		i_rs1_opd_vld;
input wire [31:0]	i_rt1_opd_data;
output wire		o_rt1_opd_rd;
input wire		i_rt1_opd_vld;
input wire [31:0]	i_rs2_opd_data;
output wire		o_rs2_opd_rd;
input wire		i_rs2_opd_vld;
input wire [31:0]	i_rt2_opd_data;
output wire		o_rt2_opd_rd;
input wire		i_rt2_opd_vld;
input wire [31:0]	i_rs3_opd_data;
output wire		o_rs3_opd_rd;
input wire		i_rs3_opd_vld;
input wire [31:0]	i_rt3_opd_data;
output wire		o_rt3_opd_rd;
input wire		i_rt3_opd_vld;
input wire [31:0]	i_rs4_opd_data;
output wire		o_rs4_opd_rd;
input wire		i_rs4_opd_vld;
input wire [31:0]	i_rt4_opd_data;
output wire		o_rt4_opd_rd;
input wire		i_rt4_opd_vld;
input wire [31:0]	i_rs5_opd_data;
output wire		o_rs5_opd_rd;
input wire		i_rs5_opd_vld;
input wire [31:0]	i_rt5_opd_data;
output wire		o_rt5_opd_rd;
input wire		i_rt5_opd_vld;
input wire [31:0]	i_rs6_opd_data;
output wire		o_rs6_opd_rd;
input wire		i_rs6_opd_vld;
input wire [31:0]	i_rt6_opd_data;
output wire		o_rt6_opd_rd;
input wire		i_rt6_opd_vld;
input wire [31:0]	i_rs7_opd_data;
output wire		o_rs7_opd_rd;
input wire		i_rs7_opd_vld;
input wire [31:0]	i_rt7_opd_data;
output wire		o_rt7_opd_rd;
input wire		i_rt7_opd_vld;
/* Register file accumulator values */
input wire [31:0]	i_th0_acc;
input wire [31:0]	i_th1_acc;
input wire [31:0]	i_th2_acc;
input wire [31:0]	i_th3_acc;
input wire [31:0]	i_th4_acc;
input wire [31:0]	i_th5_acc;
input wire [31:0]	i_th6_acc;
input wire [31:0]	i_th7_acc;
/* Register file write interface */
output reg [2:0]	o_prod_th;
output wire [2:0]	o_prod_ridx;
output reg		o_prod_wr_en;
output reg [37:0]	o_prod_data;


genvar i, j;	/* Generator block vars */


/* At least one operand FIFO is not empty */
wire in_op_fifo_busy = !t[0].r[0].op_fifo_empty || !t[0].r[1].op_fifo_empty ||
	!t[1].r[0].op_fifo_empty || !t[1].r[1].op_fifo_empty ||
	!t[2].r[0].op_fifo_empty || !t[2].r[1].op_fifo_empty ||
	!t[3].r[0].op_fifo_empty || !t[3].r[1].op_fifo_empty ||
	!t[4].r[0].op_fifo_empty || !t[4].r[1].op_fifo_empty ||
	!t[5].r[0].op_fifo_empty || !t[5].r[1].op_fifo_empty ||
	!t[6].r[0].op_fifo_empty || !t[6].r[1].op_fifo_empty ||
	!t[7].r[0].op_fifo_empty || !t[7].r[1].op_fifo_empty;

/* At least one operand receive FSM is busy */
wire in_op_fsm_busy = t[0].r[0].fsm_op_busy || t[0].r[1].fsm_op_busy ||
	t[1].r[0].fsm_op_busy || t[1].r[1].fsm_op_busy ||
	t[2].r[0].fsm_op_busy || t[2].r[1].fsm_op_busy ||
	t[3].r[0].fsm_op_busy || t[3].r[1].fsm_op_busy ||
	t[4].r[0].fsm_op_busy || t[4].r[1].fsm_op_busy ||
	t[5].r[0].fsm_op_busy || t[5].r[1].fsm_op_busy ||
	t[6].r[0].fsm_op_busy || t[6].r[1].fsm_op_busy ||
	t[7].r[0].fsm_op_busy || t[7].r[1].fsm_op_busy;


/* Threads ready to dispatch */
wire th0_rdy = !t[0].r[0].op_fifo_empty && !t[0].r[1].op_fifo_empty;
wire th1_rdy = !t[1].r[0].op_fifo_empty && !t[1].r[1].op_fifo_empty;
wire th2_rdy = !t[2].r[0].op_fifo_empty && !t[2].r[1].op_fifo_empty;
wire th3_rdy = !t[3].r[0].op_fifo_empty && !t[3].r[1].op_fifo_empty;
wire th4_rdy = !t[4].r[0].op_fifo_empty && !t[4].r[1].op_fifo_empty;
wire th5_rdy = !t[5].r[0].op_fifo_empty && !t[5].r[1].op_fifo_empty;
wire th6_rdy = !t[6].r[0].op_fifo_empty && !t[6].r[1].op_fifo_empty;
wire th7_rdy = !t[7].r[0].op_fifo_empty && !t[7].r[1].op_fifo_empty;

/* Work ready to dispatch */
wire work_rdy = th0_rdy || th1_rdy || th2_rdy || th3_rdy ||
	th4_rdy || th5_rdy || th6_rdy || th7_rdy;


/* Busy state */
assign o_busy = in_op_fifo_busy || in_op_fsm_busy || fsm_fmacd_busy || fmac_busy
	|| o_prod_wr_en; /* Extend if write enabled */


/** Internal FMAC wires and regs **/
reg [31:0]	fmac_a;
reg [31:0]	fmac_b;
reg [31:0]	fmac_c;
reg		fmac_op_vld;
wire [31:0]	fmac_p;
wire		fmac_p_vld;
/*> not used */
wire		fmac_sign;
wire		fmac_zero;
wire		fmac_nan;
wire		fmac_inf;
/*<*/

/** Internal pipe wires and regs **/
wire		fmac_busy;
reg [2:0]	pipe_op_th;
reg		pipe_op_vld;
wire [2:0]	pipe_p_th;
wire		pipe_p_th_vld;



/************ Generate per thread, per argument operand read FSMs *************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		/* Block inputs/outputs */
		wire [31:0]	i_opd_data;
		reg		o_opd_rd;
		wire		i_opd_vld;


		/*** Operand FIFO ***/
		reg [31:0]			op_fifo[0:2**IN_OP_DEPTH_POW2-1];
		reg [IN_OP_DEPTH_POW2:0]	op_fifo_rp;	/* Read pointer */
		reg [IN_OP_DEPTH_POW2:0]	op_fifo_wp;	/* Write pointer */

		/* Previous FIFO read pointer */
		wire [IN_OP_DEPTH_POW2:0]	op_fifo_pre_rp = op_fifo_rp - 1'b1;

		/* FIFO states */
		wire op_fifo_empty = (op_fifo_rp[IN_OP_DEPTH_POW2] == op_fifo_wp[IN_OP_DEPTH_POW2]) &&
			(op_fifo_rp[IN_OP_DEPTH_POW2-1:0] == op_fifo_wp[IN_OP_DEPTH_POW2-1:0]);

		wire op_fifo_full = (op_fifo_rp[IN_OP_DEPTH_POW2] != op_fifo_wp[IN_OP_DEPTH_POW2]) &&
			(op_fifo_rp[IN_OP_DEPTH_POW2-1:0] == op_fifo_wp[IN_OP_DEPTH_POW2-1:0]);

		wire op_fifo_pre_full = (op_fifo_pre_rp[IN_OP_DEPTH_POW2] != op_fifo_wp[IN_OP_DEPTH_POW2]) &&
			(op_fifo_pre_rp[IN_OP_DEPTH_POW2-1:0] == op_fifo_wp[IN_OP_DEPTH_POW2-1:0]);

		/* FIFO stall */
		wire op_fifo_stall = op_fifo_full || op_fifo_pre_full;


		/* Operand FSM */
		wire fsm_op_busy = (fsm_op != FSM_OP_IDLE);
		reg [1:0] fsm_op;

		always @(posedge clk or negedge nrst)
		begin
			if(!nrst)
			begin
				op_fifo_wp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
				o_opd_rd <= 1'b0;
				fsm_op <= FSM_OP_IDLE;
			end
			else if(fsm_op == FSM_OP_RECV)
			begin
				if(i_opd_vld)
				begin
					op_fifo[op_fifo_wp[IN_OP_DEPTH_POW2-1:0]] <= i_opd_data;
					op_fifo_wp <= op_fifo_wp + 1'b1;
				end

				if(op_fifo_stall)
				begin
					o_opd_rd <= 1'b0;
					fsm_op <= FSM_OP_STLL;
				end

				if(!i_opd_vld)
				begin
					o_opd_rd <= 1'b0;
					fsm_op <= FSM_OP_IDLE;
				end
			end
			else if(fsm_op == FSM_OP_STLL)
			begin
				if(!op_fifo_stall)
				begin
					o_opd_rd <= 1'b1;
					fsm_op <= FSM_OP_RECV;
				end
			end
			else	/* FSM_OP_IDLE */
			begin
				if(i_opd_vld)
				begin
					o_opd_rd <= 1'b1;
					fsm_op <= FSM_OP_RECV;
				end
			end
		end
	end	/* for(j, ...) */
end	/* for(i, ...) */

endgenerate


/*** Connect generated blocks ***/

/* Thread 0, Rs */
assign t[0].r[0].i_opd_data = i_rs0_opd_data;
assign o_rs0_opd_rd = t[0].r[0].o_opd_rd;
assign t[0].r[0].i_opd_vld = i_rs0_opd_vld;
/* Thread 0, Rt */
assign t[0].r[1].i_opd_data = i_rt0_opd_data;
assign o_rt0_opd_rd = t[0].r[1].o_opd_rd;
assign t[0].r[1].i_opd_vld = i_rt0_opd_vld;
/* Thread 1, Rs */
assign t[1].r[0].i_opd_data = i_rs1_opd_data;
assign o_rs1_opd_rd = t[1].r[0].o_opd_rd;
assign t[1].r[0].i_opd_vld = i_rs1_opd_vld;
/* Thread 1, Rt */
assign t[1].r[1].i_opd_data = i_rt1_opd_data;
assign o_rt1_opd_rd = t[1].r[1].o_opd_rd;
assign t[1].r[1].i_opd_vld = i_rt1_opd_vld;
/* Thread 2, Rs */
assign t[2].r[0].i_opd_data = i_rs2_opd_data;
assign o_rs2_opd_rd = t[2].r[0].o_opd_rd;
assign t[2].r[0].i_opd_vld = i_rs2_opd_vld;
/* Thread 2, Rt */
assign t[2].r[1].i_opd_data = i_rt2_opd_data;
assign o_rt2_opd_rd = t[2].r[1].o_opd_rd;
assign t[2].r[1].i_opd_vld = i_rt2_opd_vld;
/* Thread 3, Rs */
assign t[3].r[0].i_opd_data = i_rs3_opd_data;
assign o_rs3_opd_rd = t[3].r[0].o_opd_rd;
assign t[3].r[0].i_opd_vld = i_rs3_opd_vld;
/* Thread 3, Rt */
assign t[3].r[1].i_opd_data = i_rt3_opd_data;
assign o_rt3_opd_rd = t[3].r[1].o_opd_rd;
assign t[3].r[1].i_opd_vld = i_rt3_opd_vld;
/* Thread 4, Rs */
assign t[4].r[0].i_opd_data = i_rs4_opd_data;
assign o_rs4_opd_rd = t[4].r[0].o_opd_rd;
assign t[4].r[0].i_opd_vld = i_rs4_opd_vld;
/* Thread 4, Rt */
assign t[4].r[1].i_opd_data = i_rt4_opd_data;
assign o_rt4_opd_rd = t[4].r[1].o_opd_rd;
assign t[4].r[1].i_opd_vld = i_rt4_opd_vld;
/* Thread 5, Rs */
assign t[5].r[0].i_opd_data = i_rs5_opd_data;
assign o_rs5_opd_rd = t[5].r[0].o_opd_rd;
assign t[5].r[0].i_opd_vld = i_rs5_opd_vld;
/* Thread 5, Rt */
assign t[5].r[1].i_opd_data = i_rt5_opd_data;
assign o_rt5_opd_rd = t[5].r[1].o_opd_rd;
assign t[5].r[1].i_opd_vld = i_rt5_opd_vld;
/* Thread 6, Rs */
assign t[6].r[0].i_opd_data = i_rs6_opd_data;
assign o_rs6_opd_rd = t[6].r[0].o_opd_rd;
assign t[6].r[0].i_opd_vld = i_rs6_opd_vld;
/* Thread 6, Rt */
assign t[6].r[1].i_opd_data = i_rt6_opd_data;
assign o_rt6_opd_rd = t[6].r[1].o_opd_rd;
assign t[6].r[1].i_opd_vld = i_rt6_opd_vld;
/* Thread 7, Rs */
assign t[7].r[0].i_opd_data = i_rs7_opd_data;
assign o_rs7_opd_rd = t[7].r[0].o_opd_rd;
assign t[7].r[0].i_opd_vld = i_rs7_opd_vld;
/* Thread 7, Rt */
assign t[7].r[1].i_opd_data = i_rt7_opd_data;
assign o_rt7_opd_rd = t[7].r[1].o_opd_rd;
assign t[7].r[1].i_opd_vld = i_rt7_opd_vld;



/************************* FMAC scheduling logic ******************************/


/* Dispatch FSM */
wire fsm_fmacd_busy = (fsm_fmacd != FSM_FMACD_IDLE);
reg [4:0] fsm_fmacd;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		t[0].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[0].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[1].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[1].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[2].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[2].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[3].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[3].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[4].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[4].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[5].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[5].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[6].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[6].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[7].r[0].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};
		t[7].r[1].op_fifo_rp <= {(IN_OP_DEPTH_POW2+1){1'b0}};

		fsm_fmacd <= FSM_FMACD_IDLE;
		fmac_op_vld <= 1'b0;
		pipe_op_vld <= 1'b0;
	end
	else
	begin
		fmac_op_vld <= 1'b0;
		pipe_op_vld <= 1'b0;

		case(fsm_fmacd)
		FSM_FMACD_THR0: begin
			if(th0_rdy)
			begin
				fmac_a <= i_th0_acc;
				fmac_b <= t[0].r[0].op_fifo[ t[0].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[0].r[1].op_fifo[ t[0].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h0;
				t[0].r[0].op_fifo_rp <= t[0].r[0].op_fifo_rp + 1'b1;
				t[0].r[1].op_fifo_rp <= t[0].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= FSM_FMACD_THR1;
		end
		FSM_FMACD_THR1: begin
			if(th1_rdy)
			begin
				fmac_a <= i_th1_acc;
				fmac_b <= t[1].r[0].op_fifo[ t[1].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[1].r[1].op_fifo[ t[1].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h1;
				t[1].r[0].op_fifo_rp <= t[1].r[0].op_fifo_rp + 1'b1;
				t[1].r[1].op_fifo_rp <= t[1].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= FSM_FMACD_THR2;
		end
		FSM_FMACD_THR2: begin
			if(th2_rdy)
			begin
				fmac_a <= i_th2_acc;
				fmac_b <= t[2].r[0].op_fifo[ t[2].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[2].r[1].op_fifo[ t[2].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h2;
				t[2].r[0].op_fifo_rp <= t[2].r[0].op_fifo_rp + 1'b1;
				t[2].r[1].op_fifo_rp <= t[2].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= FSM_FMACD_THR3;
		end
		FSM_FMACD_THR3: begin
			if(th3_rdy)
			begin
				fmac_a <= i_th3_acc;
				fmac_b <= t[3].r[0].op_fifo[ t[3].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[3].r[1].op_fifo[ t[3].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h3;
				t[3].r[0].op_fifo_rp <= t[3].r[0].op_fifo_rp + 1'b1;
				t[3].r[1].op_fifo_rp <= t[3].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= FSM_FMACD_THR4;
		end
		FSM_FMACD_THR4: begin
			if(th4_rdy)
			begin
				fmac_a <= i_th4_acc;
				fmac_b <= t[4].r[0].op_fifo[ t[4].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[4].r[1].op_fifo[ t[4].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h4;
				t[4].r[0].op_fifo_rp <= t[4].r[0].op_fifo_rp + 1'b1;
				t[4].r[1].op_fifo_rp <= t[4].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= FSM_FMACD_THR5;
		end
		FSM_FMACD_THR5: begin
			if(th5_rdy)
			begin
				fmac_a <= i_th5_acc;
				fmac_b <= t[5].r[0].op_fifo[ t[5].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[5].r[1].op_fifo[ t[5].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h5;
				t[5].r[0].op_fifo_rp <= t[5].r[0].op_fifo_rp + 1'b1;
				t[5].r[1].op_fifo_rp <= t[5].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= FSM_FMACD_THR6;
		end
		FSM_FMACD_THR6: begin
			if(th6_rdy)
			begin
				fmac_a <= i_th6_acc;
				fmac_b <= t[6].r[0].op_fifo[ t[6].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[6].r[1].op_fifo[ t[6].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h6;
				t[6].r[0].op_fifo_rp <= t[6].r[0].op_fifo_rp + 1'b1;
				t[6].r[1].op_fifo_rp <= t[6].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= FSM_FMACD_THR7;
		end
		FSM_FMACD_THR7: begin
			if(th7_rdy)
			begin
				fmac_a <= i_th7_acc;
				fmac_b <= t[7].r[0].op_fifo[ t[7].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				fmac_c <= t[7].r[1].op_fifo[ t[7].r[0].op_fifo_rp[IN_OP_DEPTH_POW2-1:0] ];
				pipe_op_th <= 3'h7;
				t[7].r[0].op_fifo_rp <= t[7].r[0].op_fifo_rp + 1'b1;
				t[7].r[1].op_fifo_rp <= t[7].r[1].op_fifo_rp + 1'b1;
				fmac_op_vld <= 1'b1;
				pipe_op_vld <= 1'b1;
			end
			fsm_fmacd <= work_rdy ? FSM_FMACD_THR0 : FSM_FMACD_IDLE;
		end
		FSM_FMACD_ERRF: begin
			t[0].r[0].op_fifo_rp <= t[0].r[0].op_fifo_wp;
			t[0].r[1].op_fifo_rp <= t[0].r[1].op_fifo_wp;
			t[1].r[0].op_fifo_rp <= t[1].r[0].op_fifo_wp;
			t[1].r[1].op_fifo_rp <= t[1].r[1].op_fifo_wp;
			t[2].r[0].op_fifo_rp <= t[2].r[0].op_fifo_wp;
			t[2].r[1].op_fifo_rp <= t[2].r[1].op_fifo_wp;
			t[3].r[0].op_fifo_rp <= t[3].r[0].op_fifo_wp;
			t[3].r[1].op_fifo_rp <= t[3].r[1].op_fifo_wp;
			t[4].r[0].op_fifo_rp <= t[4].r[0].op_fifo_wp;
			t[4].r[1].op_fifo_rp <= t[4].r[1].op_fifo_wp;
			t[5].r[0].op_fifo_rp <= t[5].r[0].op_fifo_wp;
			t[5].r[1].op_fifo_rp <= t[5].r[1].op_fifo_wp;
			t[6].r[0].op_fifo_rp <= t[6].r[0].op_fifo_wp;
			t[6].r[1].op_fifo_rp <= t[6].r[1].op_fifo_wp;
			t[7].r[0].op_fifo_rp <= t[7].r[0].op_fifo_wp;
			t[7].r[1].op_fifo_rp <= t[7].r[1].op_fifo_wp;

			if(!in_op_fsm_busy)
				fsm_fmacd <= FSM_FMACD_IDLE;
		end
		default: begin
			if(work_rdy)
				fsm_fmacd <= FSM_FMACD_THR0;
		end
		endcase

		/* Check if error occurred */
		if(i_err_flush)
			fsm_fmacd <= FSM_FMACD_ERRF;
	end
end



/**************************** Writeback logic *********************************/


/* Register index for accumulator */
assign o_prod_ridx = VPU_REG_IDX_ACC;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		o_prod_wr_en <= 1'b0;
	end
	else
	begin
		o_prod_wr_en <= 1'b0;
		if(fmac_p_vld)
		begin
			o_prod_th <= pipe_p_th;
			o_prod_data <= { 6'h0, fmac_p };
			o_prod_wr_en <= 1'b1;
		end
		/* For debug */
		if(fmac_p_vld != pipe_p_th_vld)
			$display("vxe_vpu_prod_eu_fmac: wrong pipe timing!");
	end
end



/**************************** Block instances *********************************/

/* FP32 5-stage mac  */
flp32_mac_5stg flp32_mac0(
	.clk(clk),
	.nrst(nrst),
	.i_a(fmac_a),
	.i_b(fmac_b),
	.i_c(fmac_c),
	.i_valid(fmac_op_vld),
	.o_p(fmac_p),
	.o_sign(fmac_sign),
	.o_zero(fmac_zero),
	.o_nan(fmac_nan),
	.o_inf(fmac_inf),
	.o_valid(fmac_p_vld)
);



/* Pipe instance */
vxe_pipe_2 #(
	.DATA_WIDTH(3),
	.NSTAGES(5)
) pipe0 (
	.clk(clk),
	.nrst(nrst),
	.o_busy(fmac_busy),
	.i_data(pipe_op_th),
	.i_vld(pipe_op_vld),
	.o_data(pipe_p_th),
	.o_vld(pipe_p_th_vld)
);


endmodule /* vxe_vpu_prod_eu_fmac */
