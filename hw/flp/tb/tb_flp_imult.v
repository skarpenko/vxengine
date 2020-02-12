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
 * Testbench for integer multiplier module
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_imult();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg [31:0] mlpr;
	reg [31:0] mlpd;
	wire [63:0] prod;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_imult);

		clk = 1;
		mlpr = 32'h0000_0000;
		mlpd = 32'h0000_0000;

		#(2*PCLK)

		mlpr = 32'h0000_0001;
		mlpd = 32'h0000_0000;

		#(2*PCLK)

		mlpr = 32'h0000_0000;
		mlpd = 32'h0000_0001;

		#(2*PCLK)

		mlpr = 32'h0000_1000;
		mlpd = 32'h0000_1000;

		#(2*PCLK)

		mlpr = 32'h0001_1010;
		mlpd = 32'h0010_1001;

		#(2*PCLK)

		mlpr = 32'hffff_ffff;
		mlpd = 32'hffff_ffff;

		#(2*PCLK)

		mlpr = 32'h0000_0002;
		mlpd = 32'h0000_0003;

		#500 $finish;
	end


	/* 32-bit integer multiplier instance  */
	flp_imult #(
		.WIDTH(32)
	) imul32 (
		.i_mlpr(mlpr),
		.i_mlpd(mlpd),
		.o_prod(prod)
	);

endmodule /* tb_flp_imult */
