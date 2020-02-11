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
 * Floating point unpack
 */

module flp_unpack(
	i_fpd,
	o_sn,
	o_ex,
	o_sg,
	o_zero,
	o_nan,
	o_inf
);
parameter EWIDTH = 8;	/* Exponent width */
parameter SWIDTH = 23;	/* Significand width */
/* Inputs */
input wire [EWIDTH+SWIDTH:0]	i_fpd;	/* Floating point data */
/* Outputs */
output wire			o_sn;	/* Sign */
output wire [EWIDTH-1:0]	o_ex;	/* Exponent */
output wire [SWIDTH:0]		o_sg;	/* Significand (and hidden one) */
output wire			o_zero;	/* Zero */
output wire			o_nan;	/* NaN */
output wire			o_inf;	/* Inf */


/* Extract fields */
wire			sn = i_fpd[EWIDTH+SWIDTH];
wire [EWIDTH-1:0]	ex = i_fpd[EWIDTH+SWIDTH-1:SWIDTH];
wire [SWIDTH:0]		sg = { 1'b1, i_fpd[SWIDTH-1:0] };
/* Note: significand also includes hidden one */


wire zero = ~(|ex);	/* Check for zero (subnormals are considered as zero) */

wire aex = &ex;			/* Check if all exponent bits set */
wire osg = |sg[SWIDTH-1:0];	/* Check if significand is non-zero */

wire nan = aex & osg;	/* NaN condition */
wire inf = aex & ~osg;	/* Inf condition */


/* Assign outputs */
assign o_sn = sn;
assign o_ex = ex;
assign o_sg = zero ? {SWIDTH+1{1'b0}} : sg;
assign o_zero = zero;
assign o_nan = nan;
assign o_inf = inf;


endmodule /* flp_unpack */
