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
 * Parameterized FIFOv2 (It is built out of flops and must be short.)
 */


/* FIFO with reset */
module vxe_fifo_2 #(
	parameter DATA_WIDTH = 32,	/* FIFO data width */
	parameter DEPTH_POW2 = 2,	/* FIFO depth = 2^DEPTH_POW2 */
	parameter USE_EMPTY1 = 0	/* Use empty1 signal - one slot left. */
)
(
	clk,
	nrst,
	/* Data read/write */
	data_in,
	data_out,
	wr,
	rd,
	/* Control */
	srst,
	/* State */
	full,
	empty1,
	empty
);
input wire			clk;
input wire			nrst;
/* Data read/write */
input wire [DATA_WIDTH-1:0]	data_in;
output wire [DATA_WIDTH-1:0]	data_out;
input wire			wr;
input wire			rd;
/* Control */
input wire			srst;	/* Synchronous reset */
/* State */
output wire			full;
output wire			empty1;	/* One empty slot left */
output wire			empty;


reg [DATA_WIDTH-1:0]	fifo_buf[0:2**DEPTH_POW2-1];	/* FIFO buffer */
reg [DEPTH_POW2:0]	wr_p;				/* Write pointer */
reg [DEPTH_POW2:0]	rd_p;				/* Read pointer */

/* FIFO states */
assign empty = (wr_p[DEPTH_POW2-1:0] == rd_p[DEPTH_POW2-1:0]) &&
	(wr_p[DEPTH_POW2] == rd_p[DEPTH_POW2]);
assign full = (wr_p[DEPTH_POW2-1:0] == rd_p[DEPTH_POW2-1:0]) &&
	(wr_p[DEPTH_POW2] != rd_p[DEPTH_POW2]);

if(USE_EMPTY1 != 0)
begin
	wire [DEPTH_POW2:0] rd_p1 = rd_p - 1'b1;
	assign empty1 = (wr_p[DEPTH_POW2-1:0] == rd_p1[DEPTH_POW2-1:0]) &&
		(wr_p[DEPTH_POW2] != rd_p1[DEPTH_POW2]);
end
else
begin
	assign empty1 = 1'b0;
end


/* Write logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		wr_p <= {(DEPTH_POW2+1){1'b0}};
	end
	else if(srst)
	begin
		wr_p <= {(DEPTH_POW2+1){1'b0}};
	end
	else if(wr && !full)
	begin
		fifo_buf[wr_p[DEPTH_POW2-1:0]] <= data_in;
		wr_p <= wr_p + 1'b1;
	end
end


/* Read logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rd_p <= {(DEPTH_POW2+1){1'b0}};
	end
	else if(srst)
	begin
		rd_p <= {(DEPTH_POW2+1){1'b0}};
	end
	else if(rd && !empty)
	begin
		rd_p <= rd_p + 1'b1;
	end
end

assign data_out = fifo_buf[rd_p[DEPTH_POW2-1:0]];


endmodule /* vxe_fifo_2 */
