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
 * Testbench for FIFO
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_fifo();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg nrst;
	reg [31:0] data_in;
	wire [31:0] data_out;
	reg rd;
	reg wr;
	wire in_rdy;
	wire out_vld;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_fifo);

		clk = 1'b1;
		nrst = 1'b0;
		data_in = 32'b0;
		rd = 1'b0;
		wr = 1'b0;
		#(10*PCLK) nrst = 1'b1;

		/* Sequence of writes */
		@(posedge clk)
		begin
			data_in <= 32'hBEEF_CAFE;
			wr <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		/* Sequence of reads */
		@(posedge clk)
		begin
			wr <= 1'b0;
			rd <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			wr <= 1'b0;
			rd <= 1'b0;
		end

		/* Sequence of writes of incremented values */
		@(posedge clk)
		begin
			data_in <= 32'hBEEF_0001;
			wr <= 1'b1;
		end

		@(posedge clk)
		begin
			data_in <= 32'hBEEF_0002;
		end

		@(posedge clk)
		begin
			data_in <= 32'hBEEF_0003;
		end

		@(posedge clk)
		begin
			data_in <= 32'hBEEF_0004;
		end

		@(posedge clk)
		begin
			data_in <= 32'hBEEF_0005;
		end

		/* Sequence of reads */
		@(posedge clk)
		begin
			wr <= 1'b0;
			rd <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			wr <= 1'b0;
			rd <= 1'b0;
		end

		/* Sequence of reads and writes */
		@(posedge clk)
		begin
			data_in <= 32'hBEEF_BEEF;
			wr <= 1'b1;
			rd <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			wr <= 1'b0;
		end

		@(posedge clk)
		begin
			rd <= 1'b0;
		end


		#500 $finish;
	end


	/* FIFO instance */
	vxe_fifo #(
		.DATA_WIDTH(32),
		.DEPTH_POW2(2)
	) fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(data_in),
		.data_out(data_out),
		.rd(rd),
		.wr(wr),
		.in_rdy(in_rdy),
		.out_vld(out_vld)
	);

endmodule /* tb_vxe_fifo */
