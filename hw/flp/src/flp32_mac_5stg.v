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
 * Single precision 5-stage floating point multiply-accumulate
 */

module flp32_mac_5stg(
	clk,
	nrst,
	/* Input operands */
	i_a,
	i_b,
	i_c,
	i_valid,
	/* Result */
	o_p,
	o_sign,
	o_zero,
	o_nan,
	o_inf,
	o_valid
);
localparam EWIDTH = 8;		/* Exponent width */
localparam SWIDTH = 23;		/* Significand width */
localparam RSWIDTH = 23;	/* Reserved width for rounding */
localparam FWIDTH = 1 + EWIDTH + SWIDTH;
localparam [EWIDTH-1:0] BIAS = (1 << (EWIDTH - 1)) - 1;
/* Integer multiplier stages params */
localparam L0 = 0;
localparam H0 = 7;
localparam L1 = 8;
localparam H1 = 15;
localparam L2 = 16;
localparam H2 = 23;
/* Inputs */
input wire			clk;
input wire			nrst;
input wire [FWIDTH-1:0]		i_a;		/* Accumulator */
input wire [FWIDTH-1:0]		i_b;
input wire [FWIDTH-1:0]		i_c;
input wire			i_valid;	/* Inputs valid */
/* Outputs */
output wire [FWIDTH-1:0]	o_p;		/* Result */
output wire			o_sign;		/* Negative result */
output wire			o_zero;		/* Result is zero */
output wire			o_nan;		/* Result is NaN */
output wire			o_inf;		/* Result is Inf */
output wire			o_valid;	/* Outputs valid */



/***************************** STAGE 0 ****************************************/

reg [FWIDTH-1:0]	a_p0;
reg [FWIDTH-1:0]	b_p0;
reg [FWIDTH-1:0]	c_p0;
reg			valid_p0;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		valid_p0 <= 1'b0;
	end
	else
	begin
		valid_p0 <= i_valid;

		if(i_valid)
		begin
			a_p0 <= i_a;
			b_p0 <= i_b;
			c_p0 <= i_c;
		end
	end
end


/**** Unpack floating point data ****/

/* Unpacked a */
wire			u_sna_p0;
wire [EWIDTH-1:0]	u_exa_p0;
wire [SWIDTH:0]		u_sga_p0;
wire			u_zeroa_p0;
wire			u_nana_p0;
wire			u_infa_p0;
/* Unpacked b */
wire			u_snb_p0;
wire [EWIDTH-1:0]	u_exb_p0;
wire [SWIDTH:0]		u_sgb_p0;
wire			u_zerob_p0;
wire			u_nanb_p0;
wire			u_infb_p0;
/* Unpacked c */
wire			u_snc_p0;
wire [EWIDTH-1:0]	u_exc_p0;
wire [SWIDTH:0]		u_sgc_p0;
wire			u_zeroc_p0;
wire			u_nanc_p0;
wire			u_infc_p0;


flp_unpack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) unpack_a_p0 (
	.i_fpd(a_p0),
	.o_sn(u_sna_p0),
	.o_ex(u_exa_p0),
	.o_sg(u_sga_p0),
	.o_zero(u_zeroa_p0),
	.o_nan(u_nana_p0),
	.o_inf(u_infa_p0)
);

flp_unpack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) unpack_b_p0 (
	.i_fpd(b_p0),
	.o_sn(u_snb_p0),
	.o_ex(u_exb_p0),
	.o_sg(u_sgb_p0),
	.o_zero(u_zerob_p0),
	.o_nan(u_nanb_p0),
	.o_inf(u_infb_p0)
);

flp_unpack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) unpack_c_p0 (
	.i_fpd(c_p0),
	.o_sn(u_snc_p0),
	.o_ex(u_exc_p0),
	.o_sg(u_sgc_p0),
	.o_zero(u_zeroc_p0),
	.o_nan(u_nanc_p0),
	.o_inf(u_infc_p0)
);


/**** Multiply / Stage 0 ****/

wire [2*(SWIDTH+1)-1:0] m_sgp_p0;


flp_imult_stage #(
	.WIDTH(SWIDTH+1),
	.L(L0),
	.H(H0)
) imult_p0 (
	.i_mlpr(u_sgb_p0),
	.i_mlpd(u_sgc_p0),
	.i_prod({2*(SWIDTH+1){1'b0}}),
	.o_prod(m_sgp_p0)
);



/***************************** STAGE 1 ****************************************/

reg			valid_p1;
reg			u_sna_p1;
reg [EWIDTH-1:0]	u_exa_p1;
reg [SWIDTH:0]		u_sga_p1;
reg			u_zeroa_p1;
reg			u_nana_p1;
reg			u_infa_p1;
reg			u_snb_p1;
reg [EWIDTH-1:0]	u_exb_p1;
reg [SWIDTH:0]		u_sgb_p1;
reg			u_zerob_p1;
reg			u_nanb_p1;
reg			u_infb_p1;
reg			u_snc_p1;
reg [EWIDTH-1:0]	u_exc_p1;
reg [SWIDTH:0]		u_sgc_p1;
reg			u_zeroc_p1;
reg			u_nanc_p1;
reg			u_infc_p1;
reg [2*(SWIDTH+1)-1:0]	m_psgp_p1;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		valid_p1 <= 1'b0;
	end
	else
	begin
		valid_p1 <= valid_p0;

		if(valid_p0)
		begin
			u_sna_p1 <= u_sna_p0;
			u_exa_p1 <= u_exa_p0;
			u_sga_p1 <= u_sga_p0;
			u_zeroa_p1 <= u_zeroa_p0;
			u_nana_p1 <= u_nana_p0;
			u_infa_p1 <= u_infa_p0;
			u_snb_p1 <= u_snb_p0;
			u_exb_p1 <= u_exb_p0;
			u_sgb_p1 <= u_sgb_p0;
			u_zerob_p1 <= u_zerob_p0;
			u_nanb_p1 <= u_nanb_p0;
			u_infb_p1 <= u_infb_p0;
			u_snc_p1 <= u_snc_p0;
			u_exc_p1 <= u_exc_p0;
			u_sgc_p1 <= u_sgc_p0;
			u_zeroc_p1 <= u_zeroc_p0;
			u_nanc_p1 <= u_nanc_p0;
			u_infc_p1 <= u_infc_p0;
			m_psgp_p1 <= m_sgp_p0;
		end
	end
end


/**** Multiply / Stage 1 ****/

wire [2*(SWIDTH+1)-1:0] m_sgp_p1;


flp_imult_stage #(
	.WIDTH(SWIDTH+1),
	.L(L1),
	.H(H1)
) imult_p1 (
	.i_mlpr(u_sgb_p1),
	.i_mlpd(u_sgc_p1),
	.i_prod(m_psgp_p1),
	.o_prod(m_sgp_p1)
);

/**** Flags and exponent ****/

/* Exponent */
wire [EWIDTH+1:0] m_exp_t_p1 = { 2'b00, u_exb_p1 } + { 2'b00, u_exc_p1 }
				- { 2'b00, BIAS };
/* Flags */
wire m_sn_p1 = u_snb_p1 ^ u_snc_p1;
wire m_uf_p1 = m_exp_t_p1[EWIDTH+1];
wire m_of_p1 = m_exp_t_p1[EWIDTH] & ~m_uf_p1;
wire m_zero_p1 = u_zerob_p1 | u_zeroc_p1 | m_uf_p1;
wire m_nan_p1 = u_nanb_p1 | u_nanc_p1 | (u_zerob_p1 & u_infc_p1) |
			(u_zeroc_p1 & u_infb_p1);
wire m_inf_p1 = u_infb_p1 | u_infc_p1 | m_of_p1;
wire [EWIDTH-1:0] m_exp_p1 = m_exp_t_p1[EWIDTH-1:0];



/***************************** STAGE 2 ****************************************/

reg			valid_p2;
reg			u_sna_p2;
reg [EWIDTH-1:0]	u_exa_p2;
reg [SWIDTH:0]		u_sga_p2;
reg			u_zeroa_p2;
reg			u_nana_p2;
reg			u_infa_p2;
reg [SWIDTH:0]		u_sgb_p2;
reg [SWIDTH:0]		u_sgc_p2;
reg			m_sn_p2;
reg			m_zero_p2;
reg			m_nan_p2;
reg			m_inf_p2;
reg [2*(SWIDTH+1)-1:0]	m_psgp_p2;
reg [EWIDTH-1:0]	m_pexp_p2;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		valid_p2 <= 1'b0;
	end
	else
	begin
		valid_p2 <= valid_p1;

		if(valid_p1)
		begin
			u_sna_p2 <= u_sna_p1;
			u_exa_p2 <= u_exa_p1;
			u_sga_p2 <= u_sga_p1;
			u_zeroa_p2 <= u_zeroa_p1;
			u_nana_p2 <= u_nana_p1;
			u_infa_p2 <= u_infa_p1;
			u_sgb_p2 <= u_sgb_p1;
			u_sgc_p2 <= u_sgc_p1;
			m_sn_p2 <= m_sn_p1;
			m_zero_p2 <= m_zero_p1;
			m_nan_p2 <= m_nan_p1;
			m_inf_p2 <= m_inf_p1;
			m_psgp_p2 <= m_sgp_p1;
			m_pexp_p2 <= m_exp_p1;
		end
	end
end


/**** Multiply / Stage 2 ****/

wire [2*(SWIDTH+1)-1:0] m_sgp_t_p2;


flp_imult_stage #(
	.WIDTH(SWIDTH+1),
	.L(L2),
	.H(H2)
) imult_p2 (
	.i_mlpr(u_sgb_p2),
	.i_mlpd(u_sgc_p2),
	.i_prod(m_psgp_p2),
	.o_prod(m_sgp_t_p2)
);

/* Result */
wire [SWIDTH+RSWIDTH+1:0] m_sgp_p2 = m_zero_p2 ? {SWIDTH+RSWIDTH+2{1'b0}} :
	m_sgp_t_p2;
wire [EWIDTH-1:0] m_exp_p2 = m_zero_p2 ? {EWIDTH{1'b0}} : m_pexp_p2;



/***************************** STAGE 3 ****************************************/

reg				valid_p3;
reg				u_sna_p3;
reg [EWIDTH-1:0]		u_exa_p3;
reg [SWIDTH:0]			u_sga_p3;
reg				u_zeroa_p3;
reg				u_nana_p3;
reg				u_infa_p3;
reg				m_sn_p3;
reg				m_zero_p3;
reg				m_nan_p3;
reg				m_inf_p3;
reg [SWIDTH+RSWIDTH+1:0]	m_sgp_p3;
reg [EWIDTH-1:0]		m_exp_p3;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		valid_p3 <= 1'b0;
	end
	else
	begin
		valid_p3 <= valid_p2;

		if(valid_p2)
		begin
			u_sna_p3 <= u_sna_p2;
			u_exa_p3 <= u_exa_p2;
			u_sga_p3 <= u_sga_p2;
			u_zeroa_p3 <= u_zeroa_p2;
			u_nana_p3 <= u_nana_p2;
			u_infa_p3 <= u_infa_p2;
			m_sn_p3 <= m_sn_p2;
			m_zero_p3 <= m_zero_p2;
			m_nan_p3 <= m_nan_p2;
			m_inf_p3 <= m_inf_p2;
			m_sgp_p3 <= m_sgp_p2;
			m_exp_p3 <= m_exp_p2;
		end
	end
end


/**** Align exponents ****/

wire [SWIDTH+RSWIDTH+1:0] ae_sga_p3;
wire [SWIDTH+RSWIDTH+1:0] ae_sgp_p3;
wire [EWIDTH-1:0] ae_exp_p3;


flp_alignr #(
	.EWIDTH(EWIDTH),
	.XWIDTH(SWIDTH+RSWIDTH+2)
) alignr_p3 (
	.i_sg1({ 1'b0, u_sga_p3, {RSWIDTH{1'b0}} }),
	.i_ex1(u_exa_p3),
	.i_sg2(m_sgp_p3),
	.i_ex2(m_exp_p3),
	.o_sg1(ae_sga_p3),
	.o_sg2(ae_sgp_p3),
	.o_ex(ae_exp_p3)
);


/**** Add significands ****/

wire a_sn_p3;
wire [SWIDTH+RSWIDTH+2:0] a_sg_p3;
wire a_zero_p3;


flp_iadd #(
	.WIDTH(SWIDTH+RSWIDTH+2)
) iadd_p3 (
	.i_sn1(u_sna_p3),
	.i_sg1(ae_sga_p3),
	.i_sn2(m_sn_p3),
	.i_sg2(ae_sgp_p3),
	.o_sn(a_sn_p3),
	.o_sg(a_sg_p3),
	.o_zero(a_zero_p3)
);


/***************************** STAGE 4 ****************************************/

reg				valid_p4;
reg				u_sna_p4;
reg				u_zeroa_p4;
reg				u_nana_p4;
reg				u_infa_p4;
reg				m_sn_p4;
reg				m_zero_p4;
reg				m_nan_p4;
reg				m_inf_p4;
reg [EWIDTH-1:0]		ae_exp_p4;
reg				a_sn_p4;
reg [SWIDTH+RSWIDTH+2:0]	a_sg_p4;
reg				a_zero_p4;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		valid_p4 <= 1'b0;
	end
	else
	begin
		valid_p4 <= valid_p3;

		if(valid_p3)
		begin
			u_sna_p4 <= u_sna_p3;
			u_zeroa_p4 <= u_zeroa_p3;
			u_nana_p4 <= u_nana_p3;
			u_infa_p4 <= u_infa_p3;
			m_sn_p4 <= m_sn_p3;
			m_zero_p4 <= m_zero_p3;
			m_nan_p4 <= m_nan_p3;
			m_inf_p4 <= m_inf_p3;
			ae_exp_p4 <= ae_exp_p3;
			a_sn_p4 <= a_sn_p3;
			a_sg_p4 <= a_sg_p3;
			a_zero_p4 <= a_zero_p3;
		end
	end
end


/**** Normalization ****/

wire [SWIDTH+RSWIDTH:0] n_sg_p4;
wire [EWIDTH+1:0] n_exd_p4;
wire [EWIDTH+1:0] n_exp_p4 = { 2'b0, ae_exp_p4 } + n_exd_p4;
wire n_uf_p4 = n_exp_p4[EWIDTH+1];
wire n_of_p4 = n_exp_p4[EWIDTH] & ~n_uf_p4;


flp_norm #(
	.INWIDTH(SWIDTH+RSWIDTH+3),
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH),
	.RSWIDTH(RSWIDTH)
) norm_p4 (
	.i_sg(a_sg_p4),
	.o_sg(n_sg_p4),
	.o_exd(n_exd_p4)
);


/**** Rounding ****/

wire [SWIDTH:0] r_sg_p4;
wire [EWIDTH+1:0] r_exd_p4;
wire [EWIDTH+1:0] r_exp_p4 = { 2'b0, ae_exp_p4 } + n_exd_p4 + r_exd_p4;
wire r_uf_p4 = r_exp_p4[EWIDTH+1];
wire r_of_p4 = r_exp_p4[EWIDTH] & ~r_uf_p4;


flp_round #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH),
	.RSWIDTH(RSWIDTH)
) round_p4 (
	.i_sg(n_sg_p4),
	.o_sg(r_sg_p4),
	.o_exd(r_exd_p4)
);


/**** Pack into floating point ****/

wire p_sn_p4 = (u_infa_p4 | m_inf_p4 ? (u_infa_p4 & u_sna_p4) |
			(m_inf_p4 & m_sn_p4) : a_sn_p4);
wire p_zero_p4 = (u_zeroa_p4 & m_zero_p4) | a_zero_p4 | n_uf_p4 | r_uf_p4;
wire p_nan_p4 = u_nana_p4 | m_nan_p4 | (u_infa_p4 & m_inf_p4 &
			(u_sna_p4 ^ m_sn_p4));
wire p_inf_p4 = u_infa_p4 | m_inf_p4 | n_of_p4 | r_of_p4;
wire [EWIDTH-1:0] p_ex_p4 = r_exp_p4[EWIDTH-1:0];


flp_pack #(
	.EWIDTH(EWIDTH),
	.SWIDTH(SWIDTH)
) pack_p4 (
	.i_sn(p_sn_p4),
	.i_ex(p_ex_p4),
	.i_sg(r_sg_p4),
	.i_zero(p_zero_p4),
	.i_nan(p_nan_p4),
	.i_inf(p_inf_p4),
	.o_fpd(o_p)
);

assign o_sign = p_sn_p4;
assign o_zero = p_zero_p4;
assign o_nan = p_nan_p4;
assign o_inf = p_inf_p4;
assign o_valid = valid_p4;


endmodule /* flp32_mac_5stg */
