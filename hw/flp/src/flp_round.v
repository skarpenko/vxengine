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
 * Floating point rounding module
 */

module flp_round(
	i_sg,
	o_sg,
	o_exd
);
parameter EWIDTH = 8;	/* Exponent width */
parameter SWIDTH = 23;	/* Significand width */
parameter RSWIDTH = 2;	/* Reserved witdth for rounding */
localparam INWIDTH = 1 + SWIDTH + RSWIDTH;
/* Inputs */
input wire [INWIDTH-1:0] i_sg;	/* Significand */
/* Outputs */
output reg [SWIDTH:0] o_sg;	/* Rounded significand */
output reg [EWIDTH+1:0] o_exd;	/* Exponent delta */


wire s = |i_sg[RSWIDTH-2:0];	/* Sticky bit */
wire r = i_sg[RSWIDTH-1];	/* Round bit */
wire g = i_sg[RSWIDTH];		/* Guard bit */


reg [SWIDTH+1:0]	sg;	/* Rounded significand */


/* Rounding logic */
always @(*)
begin
	sg = { 1'b0, i_sg[INWIDTH-1:RSWIDTH] };

	if((g && r) || (r && s))
		sg = { 1'b0, i_sg[INWIDTH-1:RSWIDTH] } + 1'b1;
end


/* Overflow logic */
always @(*)
begin
	o_sg = sg[SWIDTH:0];
	o_exd = {EWIDTH+2{1'b0}};

	if(sg[SWIDTH+1])
	begin
		o_sg = sg[SWIDTH+1:1];
		o_exd = { {EWIDTH+1{1'b0}}, 1'b1 };
	end
end


endmodule /* flp_round */
