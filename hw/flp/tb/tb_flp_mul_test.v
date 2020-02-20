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
 * Testbench for floating point multiplication logic
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_mul_test();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg [31:0] f_a;
	reg [31:0] f_b;
	reg [31:0] f_valid;
	wire [31:0] f_p;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_mul_test);

		clk = 1;
		f_a = 32'h0000_0000;
		f_b = 32'h0000_0000;
		f_valid = 32'h0000_0000;

		#(2*PCLK)

		f_a = 32'h405d2f1b;
		f_b = 32'h3fe4fdf4;
		f_valid = 32'h40c5d95e;

		#(2*PCLK)

		f_a = 32'h40000000;
		f_b = 32'h40800000;
		f_valid = 32'h41000000;

		#(2*PCLK)

		#500 $finish;
	end


	/* FP32 multiplication logic test instance */
	flp_mul_test #(
		.EWIDTH(8),
		.SWIDTH(23),
		.RSWIDTH(2)
	) fp32_mul_test (
		.i_a(f_a),
		.i_b(f_b),
		.o_p(f_p)
	);

endmodule /* tb_flp_mul_test */
