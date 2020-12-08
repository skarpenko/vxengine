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
 * Floating point ReLU module
 */

module flp_relu(
	i_v,
	i_l,
	i_e,
	o_r
);
parameter EWIDTH = 8;	/* Exponent width */
parameter SWIDTH = 23;	/* Significand width */
/* Inputs */
input wire [EWIDTH+SWIDTH:0]	i_v;	/* Floating point value */
input wire			i_l;	/* =1 Leaky ReLU, =0 ReLU */
input wire [EWIDTH-2:0]		i_e;	/* Exponent diff for leaky ReLU */
/* Outputs */
output wire [EWIDTH+SWIDTH:0]	o_r;	/* Floating point ReLU result */


/**** Unpack floating point data ****/

wire			u_sn;
wire [EWIDTH-1:0]	u_ex;
wire [SWIDTH:0]		u_sg;
wire			u_zero;
wire			u_nan;
wire			u_inf;

flp_unpack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) unpack_a (
	.i_fpd(i_v),
	.o_sn(u_sn),
	.o_ex(u_ex),
	.o_sg(u_sg),
	.o_zero(u_zero),
	.o_nan(u_nan),
	.o_inf(u_inf)
);


/* Adjusted exponent for leaky ReLU */
wire [EWIDTH:0]		ex_sum = { 1'b0, u_ex } + { 2'b11, i_e };
wire [EWIDTH-1:0]	lr_ex = (!ex_sum[EWIDTH] ? ex_sum[EWIDTH-1:0] :
				{EWIDTH{1'b0}});


/* Resulting values */
wire			r_sn = (!u_nan && u_sn && !i_l ? 1'b0 : u_sn);
wire [EWIDTH-1:0]	r_ex = (!u_nan && u_sn && i_l && !u_inf ? lr_ex :
				(!u_nan && u_sn && !i_l ? {EWIDTH{1'b0}} :
				u_ex));
wire [SWIDTH:0]		r_sg = (!u_nan && u_sn ? (i_l && !ex_sum[EWIDTH] ?
				u_sg : {SWIDTH+1{1'b0}}) : u_sg);


/**** Pack floating point data ****/

flp_pack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) pack (
	.i_sn(r_sn),
	.i_ex(r_ex),
	.i_sg(r_sg),
	.i_zero(1'b0),
	.i_nan(1'b0),
	.i_inf(1'b0),
	.o_fpd(o_r)
);


endmodule /* flp_relu */
