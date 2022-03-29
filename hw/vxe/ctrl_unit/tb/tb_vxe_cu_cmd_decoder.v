/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * Testbench for VxE CU command decoder
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_cu_cmd_decoder();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;

	reg [63:0]	cmd;		/* Command word */
	wire		dec_err;	/* Decode error */
	wire [4:0]	op;		/* Opcode */
	wire [7:0]	fun;		/* Function */
	wire [37:0]	pl;		/* Payload */

	reg [0:55]	test_name;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_cu_cmd_decoder);

		clk = 1;
		cmd = 64'h0;

		wait_pos_clk();


		/*** Invalid opcode ***/

		/* Bad opcode  */
		@(posedge clk)
		begin
			test_name <= "BADOP0 ";
			cmd <= { 5'h1F, 59'h00 };
		end


		/*** Valid instructions ***/

		/* NOP */
		@(posedge clk)
		begin
			test_name <= "NOP0   ";
			cmd <= { 5'h00, 59'h00 };
		end

		/* SETACC */
		@(posedge clk)
		begin
			test_name <= "SETACC0";
			cmd <= { 5'h08, 8'h01, 19'h0, 32'hffffffff };
		end

		/* SETVL */
		@(posedge clk)
		begin
			test_name <= "SETVL0 ";
			cmd <= { 5'h09, 8'h02, 31'h0, 20'h00100 };
		end

		/* SETRS */
		@(posedge clk)
		begin
			test_name <= "SETRS0 ";
			cmd <= { 5'h0C, 8'h03, 13'h0, 38'h1ffffff0 };
		end

		/* SETRT */
		@(posedge clk)
		begin
			test_name <= "SETRT0 ";
			cmd <= { 5'h0D, 8'h04, 13'h0, 38'h2ffffff0 };
		end

		/* SETRD */
		@(posedge clk)
		begin
			test_name <= "SETRD0 ";
			cmd <= { 5'h0E, 8'h05, 13'h0, 38'h3ffffff0 };
		end

		/* SETEN */
		@(posedge clk)
		begin
			test_name <= "SETEN0 ";
			cmd <= { 5'h0A, 8'h06, 50'h0, 1'b1 };
		end

		/* PROD */
		@(posedge clk)
		begin
			test_name <= "PROD0  ";
			cmd <= { 5'h01, 59'h00 };
		end

		/* STORE */
		@(posedge clk)
		begin
			test_name <= "STORE0 ";
			cmd <= { 5'h10, 59'h00 };
		end

		/* SYNC */
		@(posedge clk)
		begin
			test_name <= "SYNC0  ";
			cmd <= { 5'h18, 57'h00, 2'b11 };
		end

		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU0  ";
			cmd <= { 5'h02, 8'h00, 44'h00, 7'h0 };
		end

		/* LRELU */
		@(posedge clk)
		begin
			test_name <= "LRELU0 ";
			cmd <= { 5'h02, 8'h01, 44'h00, 7'h4 };
		end


		/*** Instructions with reserved bits violations ***/

		/* NOP */
		@(posedge clk)
		begin
			test_name <= "NOP1   ";
			cmd <= { 5'h00, 59'h01 };
		end

		/* SETACC */
		@(posedge clk)
		begin
			test_name <= "SETACC1";
			cmd <= { 5'h08, 8'h01, 19'h1, 32'hffffffff };
		end

		/* SETVL */
		@(posedge clk)
		begin
			test_name <= "SETVL1 ";
			cmd <= { 5'h09, 8'h02, 31'h1, 20'h00100 };
		end

		/* SETRS */
		@(posedge clk)
		begin
			test_name <= "SETRS1 ";
			cmd <= { 5'h0C, 8'h03, 13'h1, 38'h1ffffff0 };
		end

		/* SETRT */
		@(posedge clk)
		begin
			test_name <= "SETRT1 ";
			cmd <= { 5'h0D, 8'h04, 13'h1, 38'h2ffffff0 };
		end

		/* SETRD */
		@(posedge clk)
		begin
			test_name <= "SETRD1 ";
			cmd <= { 5'h0E, 8'h05, 13'h1, 38'h3ffffff0 };
		end

		/* SETEN */
		@(posedge clk)
		begin
			test_name <= "SETEN1 ";
			cmd <= { 5'h0A, 8'h06, 50'h1, 1'b1 };
		end

		/* PROD */
		@(posedge clk)
		begin
			test_name <= "PROD1  ";
			cmd <= { 5'h01, 59'h01 };
		end

		/* STORE */
		@(posedge clk)
		begin
			test_name <= "STORE1 ";
			cmd <= { 5'h10, 59'h01 };
		end

		/* SYNC */
		@(posedge clk)
		begin
			test_name <= "SYNC1  ";
			cmd <= { 5'h18, 57'h01, 2'b11 };
		end

		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU1  ";
			cmd <= { 5'h02, 8'h00, 44'h01, 7'h0 };
		end

		/* LRELU */
		@(posedge clk)
		begin
			test_name <= "LRELU1 ";
			cmd <= { 5'h02, 8'h01, 44'h01, 7'h4 };
		end


		/*** Instructions with thread Id violations ***/

		/* SETACC */
		@(posedge clk)
		begin
			test_name <= "SETACC2";
			cmd <= { 5'h08, 8'h10, 19'h0, 32'hffffffff };
		end

		/* SETVL */
		@(posedge clk)
		begin
			test_name <= "SETVL2 ";
			cmd <= { 5'h09, 8'h10, 31'h0, 20'h00100 };
		end

		/* SETRS */
		@(posedge clk)
		begin
			test_name <= "SETRS2 ";
			cmd <= { 5'h0C, 8'h10, 13'h0, 38'h1ffffff0 };
		end

		/* SETRT */
		@(posedge clk)
		begin
			test_name <= "SETRT2 ";
			cmd <= { 5'h0D, 8'h10, 13'h0, 38'h2ffffff0 };
		end

		/* SETRD */
		@(posedge clk)
		begin
			test_name <= "SETRD2 ";
			cmd <= { 5'h0E, 8'h10, 13'h0, 38'h3ffffff0 };
		end

		/* SETEN */
		@(posedge clk)
		begin
			test_name <= "SETEN2 ";
			cmd <= { 5'h0A, 8'h10, 50'h0, 1'b1 };
		end


		/*** Instructions with ReLU type violations ***/

		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU3  ";
			cmd <= { 5'h02, 8'h11, 44'h00, 7'h0 };
		end

		/* LRELU */
		@(posedge clk)
		begin
			test_name <= "LRELU3 ";
			cmd <= { 5'h02, 8'h11, 44'h00, 7'h4 };
		end


		#500 $finish;
	end


	/* Command decoder */
	vxe_cu_cmd_decoder decoder(
		.i_cmd(cmd),
		.o_dec_err(dec_err),
		.o_op(op),
		.o_fun(fun),
		.o_pl(pl)
	);


endmodule /* tb_vxe_cu_cmd_decoder */
