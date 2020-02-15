/*
 * Copyright (c) 2020 The VxEngine Project. All rights reserved.
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
 * Floating point normalization
 */

module flp_norm(
	i_sg,
	o_sg,
	o_exd
);
parameter INWIDTH = 32;		/* Input width */
parameter EWIDTH = 8;		/* Exponent width */
parameter SWIDTH = 23;		/* Significand width */
parameter RSWIDTH = 2;		/* Reserved width for rounding */
localparam OUTWIDTH = 1 + SWIDTH + RSWIDTH;
/* Inputs */
input wire [INWIDTH-1:0] i_sg;	/* Significand */
/* Outputs */
output reg [OUTWIDTH-1:0] o_sg;	/* Normalized significand */
output reg [EWIDTH+1:0] o_exd;	/* Exponent delta */


wire [OUTWIDTH-1:0]	sg[0:INWIDTH-1];	/* Shifted significands */
wire [EWIDTH+1:0]	exd[0:INWIDTH-1];	/* Exponent deltas */


function [EWIDTH+1:0] exd_trunc;
	input [31:0] val;
	exd_trunc = val[EWIDTH+1:0];
endfunction


genvar g;

/* Generate right shifts */
generate
for(g = INWIDTH-1; g > SWIDTH+RSWIDTH; g = g-1)
begin: shr
	flp_shrjam #(
		.INWIDTH(INWIDTH),
		.OUTWIDTH(OUTWIDTH),
		.SHAMT(g-SWIDTH-RSWIDTH)
	) shift_r (
		.in(i_sg),
		.out(sg[g])
	);

	assign exd[g] = exd_trunc(g-SWIDTH-RSWIDTH);
end
endgenerate

/* Generate left shifts */
generate
for(g = SWIDTH+RSWIDTH; g >= 0; g = g-1)
begin: shl
	flp_shlpad #(
		.INWIDTH(INWIDTH),
		.OUTWIDTH(OUTWIDTH),
		.SHAMT(SWIDTH+RSWIDTH-g)
	) shift_l (
		.in(i_sg),
		.out(sg[g])
	);

	assign exd[g] = exd_trunc(-(SWIDTH-g)-RSWIDTH);
end
endgenerate


integer i;

/* Multiplexing logic depending of MSB position */
always @(*)
begin: mux
	reg term;

	o_sg = {OUTWIDTH{1'b0}};
	o_exd = {EWIDTH+2{1'b0}};
	term = 1'b0;

	for(i = INWIDTH-1; i >= 0; i = i-1)
	begin
		if(i_sg[i] && ~term)
		begin
			o_sg = sg[i];
			o_exd = exd[i];
			term = 1'b1;
		end
	end
end


endmodule /* flp_norm */
