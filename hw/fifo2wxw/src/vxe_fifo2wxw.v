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
 * Parameterized 2W-to-W FIFO (It is built out of flops and must be short.)
 */


/* FIFO2WxW */
module vxe_fifo2wxw #(
	parameter DATA_WIDTH = 32,	/* FIFO data width */
	parameter DEPTH_POW2 = 2	/* FIFO depth = 2^DEPTH_POW2 */
)
(
	clk,
	nrst,
	/* Data read/write */
	data_in,
	data_out,
	rd,
	wr,
	/* FIFO state */
	in_rdy,
	out_vld
);
input wire			clk;
input wire			nrst;
/* Data read/write */
input wire [2*DATA_WIDTH-1:0]	data_in;
output reg [DATA_WIDTH-1:0]	data_out;
input wire			rd;
input wire [1:0]		wr;
/* FIFO state */
output wire			in_rdy;
output wire			out_vld;


assign in_rdy = fl_in_rdy && fh_in_rdy;		/* Ready to receive data */
assign out_vld = fl_out_vld || fh_out_vld;	/* Output valid */


/* Least significant data portion FIFO signals */
reg			fl_rd;
wire			fl_wr;
wire			fl_in_rdy;
wire			fl_out_vld;
wire [DATA_WIDTH-1:0]	fl_data_out;


/* Most significant data portion FIFO signals */
reg			fh_rd;
wire			fh_wr;
wire			fh_in_rdy;
wire			fh_out_vld;
wire [DATA_WIDTH-1:0]	fh_data_out;


/* FIFOs write condition */
assign fl_wr = wr[0] && in_rdy;
assign fh_wr = wr[1] && in_rdy;


/* Least significant data portion FIFO */
vxe_fifo #(
	.DATA_WIDTH(DATA_WIDTH),
	.DEPTH_POW2(DEPTH_POW2)
) fifo_lsp (
	.clk(clk),
	.nrst(nrst),
	.data_in(data_in[DATA_WIDTH-1:0]),
	.data_out(fl_data_out),
	.rd(fl_rd),
	.wr(fl_wr),
	.in_rdy(fl_in_rdy),
	.out_vld(fl_out_vld)
);


/* Most significant data portion FIFO */
vxe_fifo #(
	.DATA_WIDTH(DATA_WIDTH),
	.DEPTH_POW2(DEPTH_POW2)
) fifo_msp (
	.clk(clk),
	.nrst(nrst),
	.data_in(data_in[2*DATA_WIDTH-1:DATA_WIDTH]),
	.data_out(fh_data_out),
	.rd(fh_rd),
	.wr(fh_wr),
	.in_rdy(fh_in_rdy),
	.out_vld(fh_out_vld)
);


reg out_sel;	/* Output data select */

/* Output data selection logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		out_sel <= 1'b0;
	end
	else if(!out_vld && (fl_wr || fh_wr))
	begin
		out_sel <= ~fl_wr;
	end
	else if(out_vld && rd)
		out_sel <= ~out_sel;
end


/* MUX */
always @(*)
begin
	if(!out_sel)
	begin
		fl_rd = rd;
		fh_rd = 1'b0;
		data_out = fl_data_out;
	end
	else
	begin
		fl_rd = 1'b0;
		fh_rd = rd;
		data_out = fh_data_out;
	end
end


endmodule /* vxe_fifo2wxw */
