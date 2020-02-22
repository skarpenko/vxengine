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
 * Testbench for floating point exponent alignment module
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_align();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg [23:0] sg1;
	reg [7:0] ex1;
	reg [23:0] sg2;
	reg [7:0] ex2;
	wire [25:0] a_sg1;
	wire [25:0] a_sg2;
	wire [7:0] a_ex;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_align);

		clk = 1;
		sg1 = 24'h00_0000;
		ex1 = 8'h00;
		sg2 = 24'h00_0000;
		ex2 = 8'h00;

		#(2*PCLK)

		sg1 = 24'h00_1000;
		ex1 = 8'h82;
		sg2 = 24'h00_1000;
		ex2 = 8'h82;

		#(2*PCLK)

		sg1 = 24'h00_1000;
		ex1 = 8'h85;
		sg2 = 24'h00_1000;
		ex2 = 8'h82;

		#(2*PCLK)

		sg1 = 24'h00_1000;
		ex1 = 8'h82;
		sg2 = 24'h00_1000;
		ex2 = 8'h85;

		#500 $finish;
	end


	/* Exponent alignment module instance for FP32 */
	flp_align #(
		.EWIDTH(8),
		.SWIDTH(23),
		.RSWIDTH(2)
	) fp32_align (
		.i_sg1(sg1),
		.i_ex1(ex1),
		.i_sg2(sg2),
		.i_ex2(ex2),
		.o_sg1(a_sg1),
		.o_sg2(a_sg2),
		.o_ex(a_ex)
	);

endmodule /* tb_flp_align */
