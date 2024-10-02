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
 * Testbench for single precision 5-stage floating point multiply-accumulate
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_flp32_mac_5stg();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg nrst;
	reg [31:0] f_a;
	reg [31:0] f_b;
	reg [31:0] f_c;
	reg [31:0] f_valid;
	reg i_valid;
	wire [31:0] f_p;
	wire o_sign;
	wire o_zero;
	wire o_nan;
	wire o_inf;
	wire o_valid;

	always
		#HCLK clk = !clk;

	task wait_pos_clk;
		@(posedge clk);
	endtask

	task wait_pos_clk5;
	begin
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
	end
	endtask

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_flp32_mac_5stg);

		clk = 1;
		nrst = 0;
		f_a = 32'h0000_0000;
		f_b = 32'h0000_0000;
		f_c = 32'h0000_0000;
		f_valid = 32'h0000_0000;
		i_valid = 1'b0;

		wait_pos_clk5();

		nrst = 1;

		wait_pos_clk();

		@(posedge clk)
		begin
			f_a <= 32'h401a3237;
			f_b <= 32'h3eae76d1;
			f_c <= 32'h3ee9c749;
			f_valid <= 32'h40242756;
			i_valid <= 1'b1;
		end

		@(posedge clk)
		begin
			i_valid <= 1'b0;
		end

		wait_pos_clk5();

		@(posedge clk)
		begin
			f_a <= 32'hbe1b902b;
			f_b <= 32'h3fa40b3b;
			f_c = 32'hbea63e5b;
			f_valid <= 32'hbf116b48;
			i_valid <= 1'b1;
		end

		@(posedge clk)
		begin
			i_valid <= 1'b0;
		end

		wait_pos_clk5();

		#500 $finish;
	end


	/* FP32 5-stage mac  */
	flp32_mac_5stg flp32_mac0(
		.clk(clk),
		.nrst(nrst),
		.i_a(f_a),
		.i_b(f_b),
		.i_c(f_c),
		.i_valid(i_valid),
		.o_p(f_p),
		.o_sign(o_sign),
		.o_zero(o_zero),
		.o_nan(o_nan),
		.o_inf(o_inf),
		.o_valid(o_valid)
	);

endmodule /* tb_flp32_mac_5stg */
