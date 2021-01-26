/*
 * Copyright (c) 2020-2021 The VxEngine Project. All rights reserved.
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
 * Testbench for Pipe
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_pipe();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam NSTAGES = 5;		/* Number of pipe stages */

	reg clk;
	reg nrst;
	reg [31:0] in;
	wire [31:0] out;
	reg en;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_pipe);

		clk = 1'b1;
		nrst = 1'b0;
		in = 32'b0;
		en = 1'b1;
		#(10*PCLK) nrst = 1'b1;

		/* Pipe data */
		@(posedge clk)
			in <= 32'hBEEF_0001;

		@(posedge clk)
			in <= 32'hBEEF_0002;

		@(posedge clk)
			in <= 32'hBEEF_0003;

		@(posedge clk)
			in <= 32'hBEEF_0004;

		@(posedge clk)
			in <= 32'hBEEF_0005;

		@(posedge clk)
			in <= 32'hBEEF_0006;


		#500 $finish;
	end


	/* Pipe instance */
	vxe_pipe #(
		.DATA_WIDTH(32),
		.NSTAGES(NSTAGES)
	) pipe (
		.clk(clk),
		.nrst(nrst),
		.in(in),
		.out(out),
		.en(en)
	);

endmodule /* tb_vxe_pipe */
