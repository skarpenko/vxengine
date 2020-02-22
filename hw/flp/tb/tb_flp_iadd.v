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
 * Testbench for integer adder module
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp_iadd();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg sn1;
	reg [15:0] sg1;
	reg sn2;
	reg [15:0] sg2;
	wire sn;
	wire [16:0] sg;
	wire zero;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp_iadd);

		clk = 1;
		sn1 = 1'b0;
		sg1 = 16'h0000;
		sn2 = 1'b0;
		sg2 = 16'h0000;

		#(2*PCLK)

		sn1 = 1'b0;
		sg1 = 16'h0001;
		sn2 = 1'b0;
		sg2 = 16'h0001;

		#(2*PCLK)

		sn1 = 1'b1;
		sg1 = 16'h0001;
		sn2 = 1'b0;
		sg2 = 16'h0001;

		#(2*PCLK)

		sn1 = 1'b0;
		sg1 = 16'h0001;
		sn2 = 1'b1;
		sg2 = 16'h0003;

		#(2*PCLK)

		sn1 = 1'b0;
		sg1 = 16'hffff;
		sn2 = 1'b0;
		sg2 = 16'hffff;

		#500 $finish;
	end


	/* 16-bit integer adder instance */
	flp_iadd #(
		.WIDTH(16)
	) iadd16 (
		.i_sn1(sn1),
		.i_sg1(sg1),
		.i_sn2(sn2),
		.i_sg2(sg2),
		.o_sn(sn),
		.o_sg(sg),
		.o_zero(zero)
	);

endmodule /* tb_flp_iadd */
