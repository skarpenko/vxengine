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
 * Testbench for floating point ReLU module
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_relu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg [31:0] fpd;	/* Input */
	reg [31:0] ref;	/* Reference result */
	reg l;
	reg [6:0] e;
	wire [31:0] res	/* ReLU module result */;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_relu);

		clk = 1;
		fpd = 32'h0000_0000;
		ref = 32'h0000_0000;
		l = 1'b0;
		e = 7'b1111100;	/* -4 */

		/* ReLU */
		#(2*PCLK)
		fpd = 32'h00000000;
		ref = 32'h00000000;

		#(2*PCLK)
		fpd = 32'h80000000;
		ref = 32'h00000000;

		#(2*PCLK)
		fpd = 32'h7f800000;
		ref = 32'h7f800000;

		#(2*PCLK)
		fpd = 32'hff800000;
		ref = 32'h00000000;

		#(2*PCLK)
		fpd = 32'h7fffffff;
		ref = 32'h7fffffff;

		#(2*PCLK)
		fpd = 32'hffffffff;
		ref = 32'hffffffff;

		#(2*PCLK)
		fpd = 32'hc1800000;
		ref = 32'h00000000;

		#(2*PCLK)
		fpd = 32'h41800000;
		ref = 32'h41800000;

		/* Leaky ReLU */
		#(2*PCLK)
		l = 1'b1;
		fpd = 32'h00000000;
		ref = 32'h00000000;

		#(2*PCLK)
		fpd = 32'h00000000;
		ref = 32'h00000000;

		#(2*PCLK)
		fpd = 32'h80000000;
		ref = 32'h80000000;

		#(2*PCLK)
		fpd = 32'h7f800000;
		ref = 32'h7f800000;

		#(2*PCLK)
		fpd = 32'hff800000;
		ref = 32'hff800000;

		#(2*PCLK)
		fpd = 32'h7fffffff;
		ref = 32'h7fffffff;

		#(2*PCLK)
		fpd = 32'hffffffff;
		ref = 32'hffffffff;

		#(2*PCLK)
		fpd = 32'hc1800000;
		ref = 32'hbf800000;

		#(2*PCLK)
		fpd = 32'h41800000;
		ref = 32'h41800000;


		#500 $finish;
	end


	/* ReLU module instance for FP32 */
	flp_relu #(
		.EWIDTH(8),
		.SWIDTH(23)
	) fp32relu (
		.i_v(fpd),
		.i_l(l),
		.i_e(e),
		.o_r(res)
	);

endmodule /* tb_flp_relu */
