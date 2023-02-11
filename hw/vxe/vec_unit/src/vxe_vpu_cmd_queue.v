/*
 * Copyright (c) 2020-2023 The VxEngine Project. All rights reserved.
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
 * VxE VPU command queue
 */


/* Command queue */
module vxe_vpu_cmd_queue #(
	parameter DEPTH_POW2 = 4	/* Internal FIFO depth = 2^DEPTH_POW2 */
)
(
	clk,
	nrst,
	/* Control interface */
	i_enable,
	i_disable,
	o_busy,
	/* Ingoing commands interface */
	i_cmd_sel,
	o_cmd_ack,
	i_cmd_op,
	i_cmd_th,
	i_cmd_pl,
	/* Outgoing commands interface */
	o_vld,
	i_rd,
	o_op,
	o_th,
	o_pl,
);
/* Global signals */
input wire		clk;
input wire		nrst;
/* Control interface */
input wire		i_enable;
input wire		i_disable;
output wire		o_busy;
/* Ingoing commands interface */
input wire		i_cmd_sel;
output wire		o_cmd_ack;
input wire [4:0]	i_cmd_op;
input wire [2:0]	i_cmd_th;
input wire [47:0]	i_cmd_pl;
/* Outgoing commands interface */
output wire		o_vld;
input wire		i_rd;
output wire [4:0]	o_op;
output wire [2:0]	o_th;
output wire [47:0]	o_pl;


reg qactive;	/* Queue active */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
		qactive <= 1'b0;
	else if(qactive && i_disable)
		qactive <= 1'b0;
	else if(!qactive && i_enable)
		qactive <= 1'b1;
end


/* FIFO signals */
wire [55:0] fifo_in;
wire [55:0] fifo_out;
wire fifo_wr;
wire fifo_rd;
wire fifo_srst;
wire fifo_full;
wire fifo_empty1;	/* Not used */
wire fifo_empty;

/* Control */
assign fifo_srst = qactive && i_disable;
assign o_busy = ~fifo_empty;

/* Ingoing commands */
assign fifo_wr = qactive && i_cmd_sel;
assign o_cmd_ack = qactive ? ~fifo_full : 1'b1;
assign fifo_in = { i_cmd_op, i_cmd_th, i_cmd_pl };

/* Outgoing commands */
assign o_vld = ~fifo_empty;
assign fifo_rd = qactive && i_rd;
assign { o_op, o_th, o_pl } = fifo_out;



/* FIFO for incoming commands */
vxe_fifo_2 #(
	.DATA_WIDTH(56),
	.DEPTH_POW2(DEPTH_POW2),
	.USE_EMPTY1(0)
) cmd_fifo (
	.clk(clk),
	.nrst(nrst),
	.data_in(fifo_in),
	.data_out(fifo_out),
	.wr(fifo_wr),
	.rd(fifo_rd),
	.srst(fifo_srst),
	.full(fifo_full),
	.empty1(fifo_empty1),
	.empty(fifo_empty)
);


endmodule /* vxe_vpu_cmd_queue */
