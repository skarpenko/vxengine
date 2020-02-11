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
 * Testbench for floating point pack module
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_pack();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg sn;
	reg [7:0] ex;
	reg [23:0] sg;
	reg zero;
	reg nan;
	reg inf;
	wire [31:0] fpd;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_pack);

		clk = 1;
		sn = 1'b0;
		ex = 8'h00;
		sg = 24'h00_0000;
		zero = 1'b0;
		nan = 1'b0;
		inf = 1'b0;

		#(2*PCLK)

		sn = 1'b1;
		ex = 8'h01;
		sg = 24'h00_0001;
		zero = 1'b1;
		nan = 1'b0;
		inf = 1'b0;

		#(2*PCLK)

		sn = 1'b0;
		ex = 8'h01;
		sg = 24'h00_0001;
		zero = 1'b1;
		nan = 1'b0;
		inf = 1'b0;

		#(2*PCLK)

		sn = 1'b1;
		ex = 8'h01;
		sg = 24'h00_0001;
		zero = 1'b0;
		nan = 1'b1;
		inf = 1'b0;

		#(2*PCLK)

		sn = 1'b0;
		ex = 8'h01;
		sg = 24'h00_0001;
		zero = 1'b0;
		nan = 1'b1;
		inf = 1'b0;

		#(2*PCLK)

		sn = 1'b1;
		ex = 8'h01;
		sg = 24'h00_0001;
		zero = 1'b0;
		nan = 1'b0;
		inf = 1'b1;

		#(2*PCLK)

		sn = 1'b0;
		ex = 8'h01;
		sg = 24'h00_0001;
		zero = 1'b0;
		nan = 1'b0;
		inf = 1'b1;

		#(2*PCLK)

		sn = 1'b0;
		ex = 8'h01;
		sg = 24'h00_0001;
		zero = 1'b0;
		nan = 1'b0;
		inf = 1'b0;

		#500 $finish;
	end


	/* Pack module instance for FP32 */
	flp_pack #(
		.EWIDTH(8),
		.SWIDTH(23)
	) fp32pack (
		.i_sn(sn),
		.i_ex(ex),
		.i_sg(sg),
		.i_zero(zero),
		.i_nan(nan),
		.i_inf(inf),
		.o_fpd(fpd)
	);

endmodule /* tb_flp_pack */
