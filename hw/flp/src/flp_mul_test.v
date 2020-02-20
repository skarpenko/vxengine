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
 * Floating point multiplication logic test
 */

module flp_mul_test(
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


/**** Multiply ****/

wire [2*(SWIDTH+1)-1:0] m_pr1;
wire [EWIDTH+1:0] m_exp = { 2'b00, u_exa } + { 2'b00, u_exb } - { 2'b00, BIAS };
wire m_zero = m_exp[EWIDTH+1];
wire m_inf = m_exp[EWIDTH] & ~m_zero;


flp_imult #(
	.WIDTH(SWIDTH+1)
) imult (
	.i_mlpr(u_sga),
	.i_mlpd(u_sgb),
	.o_prod(m_pr1)
);

wire [SWIDTH+2+RSWIDTH-1:0]	m_pr2;

/* Shift right */
flp_shrjam #(
	.INWIDTH(2*(SWIDTH+1)),
	.OUTWIDTH(SWIDTH+2+RSWIDTH),
	.SHAMT(SWIDTH-RSWIDTH)
) shrjam (
	.in(m_pr1),
	.out(m_pr2)
);


/**** Normalization ****/

wire [1 + SWIDTH + RSWIDTH-1:0] n_sg;
wire [EWIDTH+2-1:0] n_exd;
wire [EWIDTH+1:0] n_exp = m_exp + n_exd;
wire n_zero = n_exp[EWIDTH+1];
wire n_inf = n_exp[EWIDTH] & ~n_zero;


flp_norm #(
	.INWIDTH(SWIDTH+2+RSWIDTH),
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH),
	.RSWIDTH(RSWIDTH)
) norm (
	.i_sg(m_pr2),
	.o_sg(n_sg),
	.o_exd(n_exd)
);


/**** Rounding ****/

wire [SWIDTH:0] r_sg;
wire [EWIDTH+2-1:0] r_exd;
wire [EWIDTH+1:0] r_exp = m_exp + n_exd + r_exd;
wire r_zero = r_exp[EWIDTH+1];
wire r_inf = r_exp[EWIDTH] & ~r_zero;


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

wire p_sn = u_sna ^ u_snb;
wire p_zero = u_zeroa | u_zerob | m_zero | n_zero | r_zero;
wire p_inf = (u_infa ^ u_infb) | m_inf | n_inf | r_inf;
wire p_nan = u_nana | u_nanb | (u_infa & u_infb);
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

endmodule /* flp_mul_test */
