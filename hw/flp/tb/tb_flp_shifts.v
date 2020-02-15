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
 * Testbench for shift modules
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_shifts();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg [31:0] shl_i;
	reg [31:0] shr_i;
	wire [31:0] shl_o;
	wire [31:0] shr_o;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_shifts);

		clk = 1;
		shl_i = 32'h0000_0000;
		shr_i = 32'h0000_0000;

		#(2*PCLK)

		shl_i = 32'h0000_0001;
		shr_i = 32'h0000_0001;

		#(2*PCLK)

		shl_i = 32'h0000_1000;
		shr_i = 32'h0000_1000;

		#(2*PCLK)

		shl_i = 32'h1000_0000;
		shr_i = 32'h1000_0000;

		#(2*PCLK)

		shl_i = 32'h1000_0000;
		shr_i = 32'h1000_0001;

		#500 $finish;
	end


	/* Shift left module instance */
	flp_shlpad #(
		.INWIDTH(32),
		.OUTWIDTH(32),
		.SHAMT(8)
	) shl (
		.in(shl_i),
		.out(shl_o)
	);

	/* Shift right module instance */
	flp_shrjam #(
		.INWIDTH(32),
		.OUTWIDTH(32),
		.SHAMT(8)
	) shr (
		.in(shr_i),
		.out(shr_o)
	);

endmodule /* tb_flp_shifts */
