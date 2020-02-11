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
 * Testbench for floating point unpack module
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_unpack();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg [31:0] fpd;
	wire sn;
	wire [7:0] ex;
	wire [23:0] sg;
	wire zero;
	wire nan;
	wire inf;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_unpack);

		clk = 1;
		fpd = 32'h0000_0000;

		#(2*PCLK)

		fpd = 32'hffff_ffff;

		#(2*PCLK)

		fpd = 32'h7f80_0000;

		#(2*PCLK)

		fpd = 32'hff80_0000;

		#(2*PCLK)

		fpd = 32'h0000_ffff;

		#(2*PCLK)

		fpd = 32'hff00_ffff;

		#(2*PCLK)

		fpd = 32'h7f00_ffff;


		#500 $finish;
	end


	/* Unpack module instance for FP32 */
	flp_unpack #(
		.EWIDTH(8),
		.SWIDTH(23)
	) fp32unpack (
		.i_fpd(fpd),
		.o_sn(sn),
		.o_ex(ex),
		.o_sg(sg),
		.o_zero(zero),
		.o_nan(nan),
		.o_inf(inf)
	);

endmodule /* tb_flp_unpack */
