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
 * Floating point pack
 */

module flp_pack(
	i_sn,
	i_ex,
	i_sg,
	i_zero,
	i_nan,
	i_inf,
	o_fpd
);
parameter EWIDTH = 8;	/* Exponent width */
parameter SWIDTH = 23;	/* Significand width */
/* Inputs */
input wire			i_sn;	/* Sign */
input wire [EWIDTH-1:0]		i_ex;	/* Exponent */
input wire [SWIDTH:0]		i_sg;	/* Significand (and hidden one) */
input wire			i_zero;	/* Zero */
input wire			i_nan;	/* NaN */
input wire			i_inf;	/* Inf */
/* Outputs */
output wire [EWIDTH+SWIDTH:0]	o_fpd;	/* Floating point data */


reg [SWIDTH-1:0]	sg;	/* Final significand value */
reg [EWIDTH-1:0]	ex;	/* Final exponent value */


/* Significand */
always @(*)
begin
	sg = i_sg[SWIDTH-1:0];
	if(i_nan)
		sg = {SWIDTH{1'b1}};
	else if(i_inf || i_zero)
		sg = {SWIDTH{1'b0}};
end


/* Exponent */
always @(*)
begin
	ex = i_ex;
	if(i_nan || i_inf)
		ex = {EWIDTH{1'b1}};
	else if(i_zero)
		ex = {EWIDTH{1'b0}};
end


/* Assign output */
assign o_fpd = { i_sn, ex, sg };


endmodule /* flp_pack */
