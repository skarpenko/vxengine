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
 * VxE CU VPU forwarding unit
 */


/* VPU forwarding unit */
module vxe_cu_vpu_fwd_unit #(
	parameter DEPTH_POW2 = 4	/* FIFO depth = 2^DEPTH_POW2 */
)
(
	clk,
	nrst,
	/* VPU forwarding interface */
	o_fwd_vpu_rdy,
	i_fwd_vpu_op,
	i_fwd_vpu_th,
	i_fwd_vpu_pl,
	i_fwd_vpu_wr,
	/* VPU command bus interface */
	o_vpu_cmd_sel,
	i_vpu_cmd_ack,
	o_vpu_cmd_op,
	o_vpu_cmd_th,
	o_vpu_cmd_pl,
	/* Status signals */
	o_pipes_active
);
/* Command FSM states */
localparam		FSM_CMD_IDLE = 1'b0;	/* Idle */
localparam		FSM_CMD_ISSUE = 1'b1;	/* Commands issue */
/* Global signals */
input wire		clk;
input wire		nrst;
/* VPU forwarding interface */
output wire		o_fwd_vpu_rdy;
input wire [4:0]	i_fwd_vpu_op;
input wire [2:0]	i_fwd_vpu_th;
input wire [47:0]	i_fwd_vpu_pl;
input wire		i_fwd_vpu_wr;
/* VPU command bus interface */
output reg		o_vpu_cmd_sel;
input wire		i_vpu_cmd_ack;
output reg [4:0]	o_vpu_cmd_op;
output reg [2:0]	o_vpu_cmd_th;
output reg [47:0]	o_vpu_cmd_pl;
/* Status signals */
output wire		o_pipes_active;


assign o_pipes_active = !fifo_empty || (cmd_tx_fsm != FSM_CMD_IDLE);
assign o_fwd_vpu_rdy = !fifo_full;


/* FIFO buffers */
reg [4:0]		fifo_vpu_op[0:2**DEPTH_POW2-1];
reg [2:0]		fifo_vpu_th[0:2**DEPTH_POW2-1];
reg [47:0]		fifo_vpu_pl[0:2**DEPTH_POW2-1];
/* Read/write pointers */
reg [DEPTH_POW2:0]	fifo_rdp;
reg [DEPTH_POW2:0]	fifo_wrp;
/* FIFO states */
wire fifo_empty = (fifo_rdp[DEPTH_POW2-1:0] == fifo_wrp[DEPTH_POW2-1:0]) &&
	(fifo_rdp[DEPTH_POW2] == fifo_wrp[DEPTH_POW2]);
wire fifo_full = (fifo_rdp[DEPTH_POW2-1:0] == fifo_wrp[DEPTH_POW2-1:0]) &&
	(fifo_rdp[DEPTH_POW2] != fifo_wrp[DEPTH_POW2]);


/* FIFO write logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
		fifo_wrp <= {(DEPTH_POW2+1){1'b0}};
	else if(!fifo_full && i_fwd_vpu_wr)
	begin
		fifo_vpu_op[fifo_wrp[DEPTH_POW2-1:0]] <= i_fwd_vpu_op;
		fifo_vpu_th[fifo_wrp[DEPTH_POW2-1:0]] <= i_fwd_vpu_th;
		fifo_vpu_pl[fifo_wrp[DEPTH_POW2-1:0]] <= i_fwd_vpu_pl;
		fifo_wrp <= fifo_wrp + 1'b1;
	end
end


/* Commands issue logic */
wire [4:0]	vpu_op = fifo_vpu_op[fifo_rdp[DEPTH_POW2-1:0]];
wire [2:0]	vpu_th = fifo_vpu_th[fifo_rdp[DEPTH_POW2-1:0]];
wire [47:0]	vpu_pl = fifo_vpu_pl[fifo_rdp[DEPTH_POW2-1:0]];

reg		cmd_tx_fsm;	/* FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fifo_rdp <= {(DEPTH_POW2+1){1'b0}};
		o_vpu_cmd_sel <= 1'b0;
		cmd_tx_fsm <= FSM_CMD_IDLE;
	end
	else if(cmd_tx_fsm == FSM_CMD_ISSUE)
	begin
		if(i_vpu_cmd_ack && !fifo_empty)
		begin
			o_vpu_cmd_op <= vpu_op;
			o_vpu_cmd_th <= vpu_th;
			o_vpu_cmd_pl <= vpu_pl;
			fifo_rdp <= fifo_rdp + 1'b1;
		end
		else if(i_vpu_cmd_ack)
		begin
			o_vpu_cmd_sel <= 1'b0;
			cmd_tx_fsm <= FSM_CMD_IDLE;
		end
	end
	else /* FSM_CMD_IDLE */
	begin
		if(!fifo_empty)
		begin
			o_vpu_cmd_sel <= 1'b1;
			o_vpu_cmd_op <= vpu_op;
			o_vpu_cmd_th <= vpu_th;
			o_vpu_cmd_pl <= vpu_pl;
			fifo_rdp <= fifo_rdp + 1'b1;
			cmd_tx_fsm <= FSM_CMD_ISSUE;
		end
	end
end


endmodule /* vxe_cu_vpu_fwd_unit */
