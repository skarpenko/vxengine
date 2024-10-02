/*
 * Copyright (c) 2020-2024 The VxEngine Project. All rights reserved.
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
 * Testbench for Pipe v2
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_pipe_2();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam NSTAGES = 5;		/* Number of pipe stages */

	reg		clk;
	reg		nrst;
	/* Status */
	wire		busy;
	/* Data in */
	reg [31:0]	i_data;
	reg		i_vld;
	/* Data out */
	wire [31:0]	o_data;
	wire		o_vld;


	always
		#HCLK clk = !clk;


	/* Wait for "posedge clk" */
	task wait_pos_clk;
	input integer j;	/* Number of cycles */
	integer i;
	begin
		for(i=0; i<j; i++)
			@(posedge clk);
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_pipe_2);

		clk = 1'b1;
		nrst = 1'b0;
		i_data = 32'b0;
		i_vld = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(4);
		/*************************************/

		/* Test 1 - single data slot */
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0001;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk) i_data <= 32'h0000_0000;


		wait_pos_clk(8);


		/* Test 2 - multiple data slots */
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0001;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_data <= 32'hBEEF_0002;
		@(posedge clk) i_data <= 32'hBEEF_0003;
		@(posedge clk) i_data <= 32'hBEEF_0004;
		@(posedge clk) i_data <= 32'hBEEF_0005;
		@(posedge clk) i_data <= 32'hBEEF_0006;
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk) i_data <= 32'h0000_0000;


		wait_pos_clk(8);


		/* Test 3 - multiple data slots with 1-cycle delays */
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0001;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0002;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0003;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0004;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0005;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk)
		begin
			i_data <= 32'hBEEF_0006;
			i_vld <= 1'b1;
		end
		@(posedge clk) i_vld <= 1'b0;
		@(posedge clk) i_data <= 32'h0000_0000;


		#500 $finish;
	end


	/* Pipe instance */
	vxe_pipe_2 #(
		.DATA_WIDTH(32),
		.NSTAGES(NSTAGES)
	) pipe (
		.clk(clk),
		.nrst(nrst),
		.o_busy(busy),
		.i_data(i_data),
		.i_vld(i_vld),
		.o_data(o_data),
		.o_vld(o_vld)
	);


endmodule /* tb_vxe_pipe_2 */
