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
 * Parameterized simple pipe v2
 */


/* Pipe */
module vxe_pipe_2 #(
	parameter DATA_WIDTH = 32,	/* Pipe data width */
	parameter NSTAGES = 1		/* Number of stages */
)
(
	clk,
	nrst,
	/* Status */
	o_busy,
	/* Data in */
	i_data,
	i_vld,
	/* Data out */
	o_data,
	o_vld
);
input wire			clk;
input wire			nrst;
/* Status */
output wire			o_busy;
/* Data in */
input wire [DATA_WIDTH-1:0]	i_data;
input wire			i_vld;
/* Data out */
output wire [DATA_WIDTH-1:0]	o_data;
output wire			o_vld;


reg [DATA_WIDTH-1:0]	stages[0:NSTAGES-1];	/* Pipe stages */
reg			vld[0:NSTAGES-1];	/* Stage data valid */
reg			pipe_en;		/* Enabled */

assign o_data = stages[0];
assign o_vld = vld[0];
assign o_busy = pipe_en;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin : reset
		integer s;

		for(s = 0; s < NSTAGES; s=s+1)
		begin
			vld[s] <= 1'b0;
		end

		pipe_en <= 1'b0;
	end
	else if(pipe_en || i_vld)
	begin : pipe
		integer s;
		reg r;

		stages[NSTAGES-1] <= i_data;
		vld[NSTAGES-1] <= i_vld;

		for(s = 1; s < NSTAGES; s=s+1)
		begin
			stages[s-1] <= stages[s];
			vld[s-1] <= vld[s];
		end

		r = i_vld;
		for(s = 1; s < NSTAGES; s=s+1)
			r = r | vld[s];

		pipe_en <= r;
	end
end


endmodule /* vxe_pipe_2 */
