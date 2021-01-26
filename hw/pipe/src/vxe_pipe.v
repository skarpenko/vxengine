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
 * Parameterized simple pipe
 */


/* Pipe */
module vxe_pipe #(
	parameter DATA_WIDTH = 32,	/* Pipe data width */
	parameter NSTAGES = 1		/* Number of stages */
)
(
	clk,
	nrst,
	/* Data in/out */
	in,
	out,
	/* Control */
	en
);
input wire			clk;
input wire			nrst;
/* Data in/out */
input wire [DATA_WIDTH-1:0]	in;
output wire [DATA_WIDTH-1:0]	out;
/* Control */
input wire			en;

reg [DATA_WIDTH-1:0]	stages[0:NSTAGES-1];	/* Pipe stages */

assign	out = stages[0];


always @(posedge clk)
begin
	if(en)
	begin : pipe
		integer s;

		stages[NSTAGES-1] <= in;

		for(s = 1; s < NSTAGES; s=s+1)
		begin
			stages[s-1] <= stages[s];
		end
	end
end


endmodule /* vxe_pipe */
