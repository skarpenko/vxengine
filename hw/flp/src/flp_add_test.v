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
 * Floating point adder logic test
 */

module flp_add_test(
	i_a,
	i_b,
	o_p
);
parameter EWIDTH = 8;		/* Exponent width */
parameter SWIDTH = 23;		/* Significand width */
parameter RSWIDTH = 2;		/* Reserved width for rounding */
localparam FWIDTH = 1 + EWIDTH + SWIDTH;
localparam [EWIDTH-1:0] BIAS = (1 << (EWIDTH - 1)) - 1;
/* Inputs */
input wire [FWIDTH-1:0]		i_a;
input wire [FWIDTH-1:0]		i_b;
/* Outputs */
output wire [FWIDTH-1:0]	o_p;


/**** Unpack floating point data ****/

/* Unpacked a */
wire			u_sna;
wire [EWIDTH-1:0]	u_exa;
wire [SWIDTH:0]		u_sga;
wire			u_zeroa;
wire			u_nana;
wire			u_infa;
/* Unpacked b */
wire			u_snb;
wire [EWIDTH-1:0]	u_exb;
wire [SWIDTH:0]		u_sgb;
wire			u_zerob;
wire			u_nanb;
wire			u_infb;


flp_unpack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) unpack_a (
	.i_fpd(i_a),
	.o_sn(u_sna),
	.o_ex(u_exa),
	.o_sg(u_sga),
	.o_zero(u_zeroa),
	.o_nan(u_nana),
	.o_inf(u_infa)
);

flp_unpack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) unpack_b (
	.i_fpd(i_b),
	.o_sn(u_snb),
	.o_ex(u_exb),
	.o_sg(u_sgb),
	.o_zero(u_zerob),
	.o_nan(u_nanb),
	.o_inf(u_infb)
);


/**** Align exponents ****/

wire [SWIDTH+RSWIDTH:0] ae_sga;
wire [SWIDTH+RSWIDTH:0] ae_sgb;
wire [EWIDTH-1:0] ae_exp;


flp_align #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH),
	.RSWIDTH(RSWIDTH)
) align (
	.i_sg1(u_sga),
	.i_ex1(u_exa),
	.i_sg2(u_sgb),
	.i_ex2(u_exb),
	.o_sg1(ae_sga),
	.o_sg2(ae_sgb),
	.o_ex(ae_exp)
);


/**** Add significands ****/

wire a_sn;
wire [SWIDTH+RSWIDTH+1:0] a_sg;
wire a_zero;


flp_iadd #(
	.WIDTH(SWIDTH+RSWIDTH+1)
) iadd (
	.i_sn1(u_sna),
	.i_sg1(ae_sga),
	.i_sn2(u_snb),
	.i_sg2(ae_sgb),
	.o_sn(a_sn),
	.o_sg(a_sg),
	.o_zero(a_zero)
);


/**** Normalization ****/

wire [SWIDTH+RSWIDTH:0] n_sg;
wire [EWIDTH+1:0] n_exd;
wire [EWIDTH+1:0] n_exp = { 2'b0, ae_exp } + n_exd;
wire n_uf = n_exp[EWIDTH+1];
wire n_of = n_exp[EWIDTH] & ~n_uf;


flp_norm #(
	.INWIDTH(SWIDTH+RSWIDTH+2),
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH),
	.RSWIDTH(RSWIDTH)
) norm (
	.i_sg(a_sg),
	.o_sg(n_sg),
	.o_exd(n_exd)
);


/**** Rounding ****/

wire [SWIDTH:0] r_sg;
wire [EWIDTH+1:0] r_exd;
wire [EWIDTH+1:0] r_exp = { 2'b0, ae_exp } + n_exd + r_exd;
wire r_uf = r_exp[EWIDTH+1];
wire r_of = r_exp[EWIDTH] & ~r_uf;


flp_round #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH),
	.RSWIDTH(RSWIDTH)
) round (
	.i_sg(n_sg),
	.o_sg(r_sg),
	.o_exd(r_exd)
);


/**** Pack into floating point ****/

wire p_sn = a_sn | (u_sna & u_snb);
wire p_zero = (u_zeroa & u_zerob) | a_zero | n_uf | r_uf;
wire p_inf = u_infa | u_infb | n_of | r_of;
wire p_nan = u_nana | u_nanb | (u_infa & u_infb & (u_sna ^ u_snb));
wire [EWIDTH-1:0] p_ex = r_exp[EWIDTH-1:0];


flp_pack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) pack (
	.i_sn(p_sn),
	.i_ex(p_ex),
	.i_sg(r_sg),
	.i_zero(p_zero),
	.i_nan(p_nan),
	.i_inf(p_inf),
	.o_fpd(o_p)
);

endmodule /* flp_add_test */
