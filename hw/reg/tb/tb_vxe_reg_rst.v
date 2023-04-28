/*
 * Copyright (c) 2020-2023 The VxEngine Project. All rights reserved.
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
 * Testbench for register with reset
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_reg_rst();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg nrst;
	reg wr_en;
	reg [31:0] data_in;
	wire [31:0] data_out;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_reg_rst);

		clk = 1'b1;
		nrst = 1'b0;
		wr_en = 1'b0;
		data_in = 32'b0;
		#(4*PCLK) nrst = 1'b1;

		/******************************/

		@(posedge clk);


		@(posedge clk)
		begin
			wr_en <= 1'b1;
			data_in <= 32'hfefe_0000;
		end
		@(posedge clk)
			wr_en <= 1'b0;


		@(posedge clk);
		@(posedge clk);
		@(posedge clk);


		@(posedge clk)
		begin
			wr_en <= 1'b1;
			data_in <= 32'hbebe_0000;
		end
		@(posedge clk)
			wr_en <= 1'b0;


		#50 $finish;
	end


	/* Register instance */
	vxe_reg_rst #(
		.DATA_WIDTH(32),
		.RST_VALUE(32'hdead_beef)
	) vxereg_rst (
		.clk(clk),
		.nrst(nrst),
		.wr_en(wr_en),
		.data_in(data_in),
		.data_out(data_out)
	);

endmodule /* tb_vxe_reg_rst */
