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
 * Integer adder
 */

module flp_iadd(
	i_sn1,
	i_sg1,
	i_sn2,
	i_sg2,
	o_sn,
	o_sg,
	o_zero
);
parameter WIDTH = 32;
/* Inputs */
input wire		i_sn1;
input wire [WIDTH-1:0]	i_sg1;
input wire		i_sn2;
input wire [WIDTH-1:0]	i_sg2;
/* Outputs */
output wire		o_sn;
output wire [WIDTH:0]	o_sg;
output wire		o_zero;


wire [WIDTH+1:0]	op1 = |i_sg1 ? { {2{i_sn1}}, (i_sn1 ? -i_sg1 : i_sg1) }
				: {WIDTH+2{1'b0}};
wire [WIDTH+1:0]	op2 = |i_sg2 ? { {2{i_sn2}}, (i_sn2 ? -i_sg2 : i_sg2) }
				: {WIDTH+2{1'b0}};
wire [WIDTH+1:0]	sum = op1 + op2;


assign o_sn = sum[WIDTH+1] | (i_sn1 & i_sn2);
assign o_zero = ~|sum;
assign o_sg = o_sn ? -sum[WIDTH:0] : sum[WIDTH:0];


endmodule /* flp_iadd */
