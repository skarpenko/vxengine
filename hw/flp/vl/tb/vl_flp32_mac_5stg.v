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
 * Single precision 5-stage floating point multiply-accumulate test
 */

module vl_flp32_mac_5stg(
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
localparam FWIDTH = 32;
/* Inputs */
input wire			clk;
input wire			nrst;
input wire [FWIDTH-1:0]		i_a;
input wire [FWIDTH-1:0]		i_b;
input wire [FWIDTH-1:0]		i_c;
input wire			i_valid;
/* Outputs */
output wire [FWIDTH-1:0]	o_p;
output wire			o_sign;
output wire			o_zero;
output wire			o_nan;
output wire			o_inf;
output wire			o_valid;


/* FP32 5-stage mac  */
flp32_mac_5stg fpl32_mac0(
	.clk(clk),
	.nrst(nrst),
	.i_a(i_a),
	.i_b(i_b),
	.i_c(i_c),
	.i_valid(i_valid),
	.o_p(o_p),
	.o_sign(o_sign),
	.o_zero(o_zero),
	.o_nan(o_nan),
	.o_inf(o_inf),
	.o_valid(o_valid)
);


endmodule /* vl_flp32_mac_5stg */
