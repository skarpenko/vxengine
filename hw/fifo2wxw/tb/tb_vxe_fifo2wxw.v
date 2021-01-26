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
 * Testbench for 2W-to-W FIFO
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_fifo2wxw();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg nrst;
	reg [63:0] data_in;
	wire [31:0] data_out;
	reg rd;
	reg [1:0] wr;
	wire in_rdy;
	wire out_vld;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_fifo2wxw);

		clk = 1'b1;
		nrst = 1'b0;
		data_in = 64'b0;
		rd = 1'b0;
		wr = 2'b00;
		#(10*PCLK) nrst = 1'b1;

		/* Sequence of writes */
		@(posedge clk)
		begin
			data_in <= 64'hBEEF_0002_BEEF_0001;
			wr <= 2'b11;
		end
		@(posedge clk)
		begin
			data_in <= 64'hBEEF_0004_BEEF_0003;
			wr <= 2'b11;
		end
		@(posedge clk)
		begin
			data_in <= 64'hBEEF_0006_BEEF_0005;
			wr <= 2'b11;
		end
		@(posedge clk)
		begin
			data_in <= 64'hBEEF_0008_BEEF_0007;
			wr <= 2'b11;
		end
		@(posedge clk) wr <= 2'b00;

		/* Sequence of reads */
		@(posedge clk) rd <= 1'b1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk) rd <= 1'b0;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);


		/* Corner cases */
		@(posedge clk)
		begin
			data_in <= 64'hBEEF_0001_FFFF_FFFF;
			wr <= 2'b10;
		end
		@(posedge clk)
		begin
			data_in <= 64'hBEEF_0003_BEEF_0002;
			wr <= 2'b11;
		end
		@(posedge clk)
		begin
			data_in <= 64'hFFFF_FFFF_BEEF_0004;
			wr <= 2'b01;
		end
		@(posedge clk) wr <= 2'b00;
		/* Reads */
		@(posedge clk) rd <= 1'b1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk) rd <= 1'b0;


		#500 $finish;
	end


	/* FIFO64x32 instance */
	vxe_fifo2wxw #(
		.DATA_WIDTH(32),
		.DEPTH_POW2(2)
	) fifo64x32 (
		.clk(clk),
		.nrst(nrst),
		.data_in(data_in),
		.data_out(data_out),
		.rd(rd),
		.wr(wr),
		.in_rdy(in_rdy),
		.out_vld(out_vld)
	);

endmodule /* tb_vxe_fifo2wxw */
