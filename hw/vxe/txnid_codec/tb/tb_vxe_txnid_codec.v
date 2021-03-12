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
 * Testbench for transaction Id coder and decoder
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_txnid_codec();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg clk;
	reg [1:0]	i_client_id;
	reg [2:0]	i_thread_id;
	reg		i_argument;
	wire [5:0]	txnid;
	wire [1:0]	o_client_id;
	wire [2:0]	o_thread_id;
	wire		o_argument;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_txnid_codec);

		clk = 1;
		i_client_id = 2'b0;
		i_thread_id = 3'b0;
		i_argument = 1'b0;


		@(posedge clk);
		@(posedge clk);


		@(posedge clk)
		begin
			i_client_id <= 2'b10;
			i_thread_id <= 3'b111;
			i_argument <= 1'b1;
		end


		@(posedge clk)
		begin
			i_client_id <= 2'b01;
			i_thread_id <= 3'b011;
			i_argument <= 1'b0;
		end


		#500 $finish;
	end


	/* TxnId coder */
	vxe_txnid_coder coder(
		.i_client_id(i_client_id),
		.i_thread_id(i_thread_id),
		.i_argument(i_argument),
		.o_txnid(txnid)
	);


	/* TxnId decoder */
	vxe_txnid_decoder decoder(
		.i_txnid(txnid),
		.o_client_id(o_client_id),
		.o_thread_id(o_thread_id),
		.o_argument(o_argument)
	);


endmodule /* tb_vxe_txnid_codec */
