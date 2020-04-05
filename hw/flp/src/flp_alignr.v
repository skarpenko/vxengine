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
 * Floating point exponent alignment module (right shift only)
 */

module flp_alignr(
	i_sg1,
	i_ex1,
	i_sg2,
	i_ex2,
	o_sg1,
	o_sg2,
	o_ex
);
parameter EWIDTH = 8;		/* Exponent width */
parameter XWIDTH = 24;		/* Extended significand width */
/* Inputs */
input wire [XWIDTH-1:0]		i_sg1;	/* Significand 1 */
input wire [EWIDTH-1:0]		i_ex1;	/* Exponent 1 */
input wire [XWIDTH-1:0]		i_sg2;	/* Significand 2 */
input wire [EWIDTH-1:0]		i_ex2;	/* Exponent 2 */
/* Outputs */
output reg [XWIDTH-1:0]		o_sg1;	/* Aligned significand 1 */
output reg [XWIDTH-1:0]		o_sg2;	/* Aligned significand 2 */
output wire [EWIDTH-1:0]	o_ex;	/* Common exponent */


wire [EWIDTH:0]		exd;	/* Exponent delta */
wire			exneg;	/* Exponent delta is negative */
wire [EWIDTH-1:0]	shamt;	/* Significand shift amount */
wire [XWIDTH-1:0]	shsg;	/* Significand which need to be shifted */
wire [XWIDTH-1:0]	sg[0:XWIDTH-1];	/* Shifted significands */

assign exd = { 1'b0, i_ex1 } - { 1'b0, i_ex2 };
assign exneg = exd[EWIDTH];
assign shamt = exneg ? -exd[EWIDTH-1:0] : exd[EWIDTH-1:0];
assign shsg = exneg ? i_sg1 : i_sg2;


genvar g;

/* Generate right shifts */
generate
for(g = XWIDTH-1; g >= 0; g = g-1)
begin: shr
	flp_shrjam #(
		.INWIDTH(XWIDTH),
		.OUTWIDTH(XWIDTH),
		.SHAMT(g)
	) shift_r (
		.in(shsg),
		.out(sg[g])
	);
end
endgenerate


assign o_ex = exneg ? i_ex2 : i_ex1;


`define IDX_WIDTH(x)		\
	(x <= 2) ? 1 :		\
	(x <= 4) ? 2 :		\
	(x <= 8) ? 3 :		\
	(x <= 16) ? 4 :		\
	(x <= 32) ? 5 :		\
	(x <= 64) ? 6 :		\
	(x <= 128) ? 7 :	\
	(x <= 256) ? 8 :	\
	-1
localparam IW = `IDX_WIDTH(XWIDTH);
`undef IDX_WIDTH

/* Multiplexing logic depending on shift amount */
always @(*)
begin
	o_sg1 = {XWIDTH{1'b0}};
	o_sg2 = {XWIDTH{1'b0}};

	if(shamt < XWIDTH)
	begin
		o_sg1 = exneg ? sg[shamt[IW-1:0]] : i_sg1;
		o_sg2 = !exneg ? sg[shamt[IW-1:0]] : i_sg2;
	end
	else
	begin
		o_sg1 = exneg ? { {XWIDTH-1{1'b0}}, |i_sg1 } : i_sg1;
		o_sg2 = !exneg ? { {XWIDTH-1{1'b0}}, |i_sg2 } : i_sg2;
	end
end


endmodule /* flp_alignr */
