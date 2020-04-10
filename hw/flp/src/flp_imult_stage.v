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
 * Integer multiplier stage (simple implementation, shift and add)
 */

module flp_imult_stage(
	i_mlpr,
	i_mlpd,
	i_prod,
	o_prod
);
parameter WIDTH = 32;	/* Multiplier operand width */
parameter L = 0;	/* Lower bit of stage bit range */
parameter H = 31;	/* Higher bit of stage bit range */
/* Inputs */
input wire [WIDTH-1:0]		i_mlpr;	/* Multiplier */
input wire [WIDTH-1:0]		i_mlpd;	/* Multiplicand */
input wire [2*WIDTH-1:0]	i_prod;	/* Product of previous stage */
/* Outputs */
output wire [2*WIDTH-1:0]	o_prod;	/* Product */


reg [2*WIDTH-1:0]	prod;		/* Product */
wire [2*WIDTH-1:0]	mlpd[L:H];	/* Shifted multiplicands */

assign o_prod = prod;	/* Assign output */


/* Generate shifted multiplicands */
genvar g;
generate
	for(g = L; g <= H; g = g + 1)
	begin: mlpd_table
		assign mlpd[g] = { {WIDTH-g{1'b0}}, i_mlpd, {g{1'b0}} };
	end
endgenerate


/* Summation */
integer i;
always @(*)
begin
	prod = i_prod;
	for(i = L; i <= H; i = i + 1)
	begin
		if(i_mlpr[i] == 1'b1)
			prod = prod + mlpd[i];
	end
end


endmodule /* flp_imult_stage */
