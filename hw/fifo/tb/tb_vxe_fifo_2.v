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
 * Testbench for FIFOv2
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_fifo_2();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg nrst;
	/* FIFO0 */
	reg [31:0] data_in0;
	wire [31:0] data_out0;
	reg wr0;
	reg rd0;
	reg srst0;
	wire full0;
	wire empty10;
	wire empty0;
	/* FIFO1 */
	reg [31:0] data_in1;
	wire [31:0] data_out1;
	reg wr1;
	reg rd1;
	reg srst1;
	wire full1;
	wire empty11;
	wire empty1;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_fifo_2);

		clk = 1'b1;
		nrst = 1'b0;
		data_in0 = 32'b0;
		rd0 = 1'b0;
		wr0 = 1'b0;
		srst0 = 1'b0;
		data_in1 = 32'b0;
		rd1 = 1'b0;
		wr1 = 1'b0;
		srst1 = 1'b0;
		#(10*PCLK) nrst = 1'b1;

		/* Sequence of writes */
		@(posedge clk)
		begin
			data_in0 <= 32'hBEEF_CAFE;
			wr0 <= 1'b1;
			data_in1 <= 32'hCAFE_BEEF;
			wr1 <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		/* Sequence of reads */
		@(posedge clk)
		begin
			wr0 <= 1'b0;
			wr1 <= 1'b0;
			rd0 <= 1'b1;
			rd1 <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			wr0 <= 1'b0;
			wr1 <= 1'b0;
			rd0 <= 1'b0;
			rd1 <= 1'b0;
		end

		/* Sequence of writes of incremented values */
		@(posedge clk)
		begin
			data_in0 <= 32'hBEEF_0001;
			wr0 <= 1'b1;
			data_in1 <= 32'hCAFE_0001;
			wr1 <= 1'b1;
		end

		@(posedge clk)
		begin
			data_in0 <= 32'hBEEF_0002;
			data_in1 <= 32'hCAFE_0002;
		end

		@(posedge clk)
		begin
			data_in0 <= 32'hBEEF_0003;
			data_in1 <= 32'hCAFE_0003;
		end

		@(posedge clk)
		begin
			data_in0 <= 32'hBEEF_0004;
			data_in1 <= 32'hCAFE_0004;
		end

		@(posedge clk)
		begin
			data_in0 <= 32'hBEEF_0005;
			data_in1 <= 32'hCAFE_0005;
		end

		/* Sequence of reads */
		@(posedge clk)
		begin
			wr0 <= 1'b0;
			wr1 <= 1'b0;
			rd0 <= 1'b1;
			rd1 <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			wr0 <= 1'b0;
			wr1 <= 1'b0;
			rd0 <= 1'b0;
			rd1 <= 1'b0;
		end

		/* Sequence of reads and writes */
		@(posedge clk)
		begin
			data_in0 <= 32'hBEEF_BEEF;
			wr0 <= 1'b1;
			rd0 <= 1'b1;
			data_in1 <= 32'hCAFE_CAFE;
			wr1 <= 1'b1;
			rd1 <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			wr0 <= 1'b0;
			wr1 <= 1'b0;
		end

		@(posedge clk)
		begin
			rd0 <= 1'b0;
			rd1 <= 1'b0;
		end

		/* Sequence of writes and reset */
		@(posedge clk)
		begin
			data_in0 <= 32'hCAFE_BEEF;
			wr0 <= 1'b1;
			data_in1 <= 32'hBEEF_CAFE;
			wr1 <= 1'b1;
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			srst0 <= 1'b1;
			srst1 <= 1'b1;
			wr0 <= 1'b0;
			wr1 <= 1'b0;
		end

		@(posedge clk)
		begin
			srst0 <= 1'b0;
			srst1 <= 1'b0;
		end


		#500 $finish;
	end


	/* FIFO0 instance */
	vxe_fifo_2 #(
		.DATA_WIDTH(32),
		.DEPTH_POW2(2),
		.USE_EMPTY1(0)
	) fifo0 (
		.clk(clk),
		.nrst(nrst),
		.data_in(data_in0),
		.data_out(data_out0),
		.wr(wr0),
		.rd(rd0),
		.srst(srst0),
		.full(full0),
		.empty1(empty10),
		.empty(empty0)
	);


	/* FIFO1 instance */
	vxe_fifo_2 #(
		.DATA_WIDTH(32),
		.DEPTH_POW2(2),
		.USE_EMPTY1(1)
	) fifo1 (
		.clk(clk),
		.nrst(nrst),
		.data_in(data_in1),
		.data_out(data_out1),
		.wr(wr1),
		.rd(rd1),
		.srst(srst1),
		.full(full1),
		.empty1(empty11),
		.empty(empty1)
	);


endmodule /* tb_vxe_fifo_2 */
