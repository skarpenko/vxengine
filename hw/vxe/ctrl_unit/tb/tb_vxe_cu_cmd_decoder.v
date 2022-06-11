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
`include "vxe_ctrl_unit_cmds.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;

	reg [63:0]	cmd;		/* Command word */
	wire		dec_err;	/* Decode error */
	wire		cu_cmd;		/* CU command */
	wire		cu_nop;		/* CU NOP */
	wire		cu_sync;	/* CU SYNC */
	wire		cu_sync_stop;	/* CU should stop */
	wire		cu_sync_intr;	/* CU should send interrupt */
	wire		vpu_cmd;	/* VPU command */
	wire [3:0]	vpu_mask;	/* VPUs mask */
	wire [4:0]	vpu_op;		/* VPU opcode */
	wire [2:0]	vpu_th;		/* VPU thread */
	wire [47:0]	vpu_pl;		/* VPU command payload */

	reg [0:55]	test_name;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	/* Generic command */
	function [63:0] cmd_generic;
		input [4:0] op;
		input [58:0] other;
		cmd_generic = { op, other };
	endfunction


	/* Generic VPU command */
	function [63:0] cmd_vpu_generic;
		input [4:0] op;
		input [7:0] dst;
		input [2:0] z0;
		input [47:0] pl;
		cmd_vpu_generic = { op, dst, z0, pl };
	endfunction


	/* Generic activation function command */
	function [63:0] cmd_af_generic;
		input [4:0] op;
		input [7:0] dst;
		input [2:0] z0;
		input [5:0] af;
		input [41:0] pl;
		cmd_af_generic = { op, dst, z0, af, pl };
	endfunction


	/* NOP - No Operation - used for padding */
	function [63:0] cmd_nop;
		input z;
		cmd_nop = cmd_generic(CU_CMD_NOP, 59'h0);
	endfunction


	/* SETACC - Set Accumulator - Set an accumulator register per VPU thread */
	function [63:0] cmd_setacc;
		input [7:0] dst;
		input [31:0] acc;
		cmd_setacc = cmd_vpu_generic(CU_CMD_SETACC, dst, 3'b0, { 16'h0, acc });
	endfunction


	/* SETVL - Set Vector Length - Set vector length per VPU thread */
	function [63:0] cmd_setvl;
		input [7:0] dst;
		input [19:0] len;
		cmd_setvl = cmd_vpu_generic(CU_CMD_SETVL, dst, 3'b0, { 28'h0, len });
	endfunction


	/* SETRS - Set First Operand - Set first operand vector per VPU thread */
	function [63:0] cmd_setrs;
		input [7:0] dst;
		input [37:0] addr;
		cmd_setrs = cmd_vpu_generic(CU_CMD_SETRS, dst, 3'b0, { 10'h0, addr });
	endfunction


	/* SETRT - Set Second Operand - Set second operand vector per VPU thread */
	function [63:0] cmd_setrt;
		input [7:0] dst;
		input [37:0] addr;
		cmd_setrt = cmd_vpu_generic(CU_CMD_SETRT, dst, 3'b0, { 10'h0, addr });
	endfunction


	/* SETRD - Set Destination - Set result destination per VPU thread */
	function [63:0] cmd_setrd;
		input [7:0] dst;
		input [37:0] addr;
		cmd_setrd = cmd_vpu_generic(CU_CMD_SETRD, dst, 3'b0, { 10'h0, addr });
	endfunction


	/* SETEN - Set Thread Enable - Enable or disable selected VPU thread */
	function [63:0] cmd_seten;
		input [7:0] dst;
		input en;
		cmd_seten = cmd_vpu_generic(CU_CMD_SETEN, dst, 3'b0, { 47'h0, en });
	endfunction


	/* PROD - Vector Product - Run enabled threads to compute vector product */
	function [63:0] cmd_prod;
		input [7:0] dst;
		cmd_prod = cmd_vpu_generic(CU_CMD_PROD, dst, 3'b0, 48'h0);
	endfunction


	/* STORE - Store Result - Store result of enabled threads */
	function [63:0] cmd_store;
		input [7:0] dst;
		cmd_store = cmd_vpu_generic(CU_CMD_STORE, dst, 3'b0, 48'h0);
	endfunction


	/* SYNC - Synchronize - Wait for completion of all previous operations */
	function [63:0] cmd_sync;
		input intr;
		input stop;
		cmd_sync = cmd_generic(CU_CMD_SYNC, { 57'h0, intr, stop});
	endfunction


	/* RELU - ReLU activation - Run ReLU on accumulators of enabled threads */
	function [63:0] cmd_relu;
		input [7:0] dst;
		cmd_relu = cmd_af_generic(CU_CMD_ACTF, dst, 3'b0, CU_CMD_ACTF_RELU, 42'h0);
	endfunction


	/* LRELU - Leaky ReLU activation - Run leaky ReLU on accumulators of enabled threads */
	function [63:0] cmd_lrelu;
		input [7:0] dst;
		input [6:0] ed;
		cmd_lrelu = cmd_af_generic(CU_CMD_ACTF, dst, 3'b0, CU_CMD_ACTF_LRELU,
			{ 35'h0, ed });
	endfunction


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
			cmd <= cmd_generic(5'h1F, 59'h00);
		end


		/*** Valid instructions ***/

		/* NOP */
		@(posedge clk)
		begin
			test_name <= "NOP0   ";
			cmd <= cmd_nop(1'b0);
		end

		/* SETACC */
		@(posedge clk)
		begin
			test_name <= "SETACC0";
			cmd <= cmd_setacc(8'h01, 32'hffffffff);
		end

		/* SETVL */
		@(posedge clk)
		begin
			test_name <= "SETVL0 ";
			cmd <= cmd_setvl(8'h02, 20'h00100);
		end

		/* SETRS */
		@(posedge clk)
		begin
			test_name <= "SETRS0 ";
			cmd <= cmd_setrs(8'h03, 38'h1ffffff0);
		end

		/* SETRT */
		@(posedge clk)
		begin
			test_name <= "SETRT0 ";
			cmd <= cmd_setrt(8'h04, 38'h2ffffff0);
		end

		/* SETRD */
		@(posedge clk)
		begin
			test_name <= "SETRD0 ";
			cmd <= cmd_setrd(8'h05, 38'h3ffffff0);
		end

		/* SETEN */
		@(posedge clk)
		begin
			test_name <= "SETEN0 ";
			cmd <= cmd_seten(8'h06, 1'b1);
		end

		/* PROD */
		@(posedge clk)
		begin
			test_name <= "PROD0  ";
			cmd <= cmd_prod(8'h00);
		end

		/* STORE */
		@(posedge clk)
		begin
			test_name <= "STORE0 ";
			cmd <= cmd_store(8'h00);
		end

		/* SYNC */
		@(posedge clk)
		begin
			test_name <= "SYNC0  ";
			cmd <= cmd_sync(1'b1, 1'b1);
		end

		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU0  ";
			cmd <= cmd_relu(8'h00);
		end

		/* LRELU */
		@(posedge clk)
		begin
			test_name <= "LRELU0 ";
			cmd <= cmd_lrelu(8'h00, 7'h4);
		end


		/*** Instructions with reserved bits violations ***/

		/* NOP */
		@(posedge clk)
		begin
			test_name <= "NOP1   ";
			cmd <= cmd_generic(CU_CMD_NOP, 59'h1);
		end

		/* SETACC */
		@(posedge clk)
		begin
			test_name <= "SETACC1";
			cmd <= cmd_vpu_generic(CU_CMD_SETACC, 8'h01, 3'h1,
				{ 16'h1, 32'heeeeeeee });
		end

		/* SETVL */
		@(posedge clk)
		begin
			test_name <= "SETVL1 ";
			cmd <= cmd_vpu_generic(CU_CMD_SETVL, 8'h02, 3'b1,
				{ 28'h1, 20'h200 });
		end

		/* SETRS */
		@(posedge clk)
		begin
			test_name <= "SETRS1 ";
			cmd <= cmd_vpu_generic(CU_CMD_SETRS, 8'h03, 3'b1,
				{ 10'h1, 38'h1ffffff0 });
		end

		/* SETRT */
		@(posedge clk)
		begin
			test_name <= "SETRT1 ";
			cmd <= cmd_vpu_generic(CU_CMD_SETRT, 8'h04, 3'b1,
				{ 10'h1, 38'h2ffffff0 });
		end

		/* SETRD */
		@(posedge clk)
		begin
			test_name <= "SETRD1 ";
			cmd <= cmd_vpu_generic(CU_CMD_SETRD, 8'h05, 3'b1,
				{ 10'h1, 38'h3ffffff0 });
		end

		/* SETEN */
		@(posedge clk)
		begin
			test_name <= "SETEN1 ";
			cmd <= cmd_vpu_generic(CU_CMD_SETEN, 8'h06, 3'b1,
				{ 47'h1, 1'b1 });
		end

		/* PROD */
		@(posedge clk)
		begin
			test_name <= "PROD1  ";
			cmd <= cmd_vpu_generic(CU_CMD_PROD, 8'h00, 3'b1, 48'h1);
		end

		/* STORE */
		@(posedge clk)
		begin
			test_name <= "STORE1 ";
			cmd <= cmd_vpu_generic(CU_CMD_STORE, 8'h00, 3'b1, 48'h1);
		end

		/* SYNC */
		@(posedge clk)
		begin
			test_name <= "SYNC1  ";
			cmd <= cmd_generic(CU_CMD_SYNC, { 57'h1, 2'b11});
		end

		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU1  ";
			cmd <= cmd_af_generic(CU_CMD_ACTF, 8'h00, 3'b1,
				CU_CMD_ACTF_RELU, 42'h1);
		end

		/* LRELU */
		@(posedge clk)
		begin
			test_name <= "LRELU1 ";
			cmd <= cmd_af_generic(CU_CMD_ACTF, 8'h00, 3'b1, CU_CMD_ACTF_LRELU,
				{ 35'h1, 7'h4 });
		end


		/*** Instructions with destination VPU violations ***/

		/* SETACC */
		@(posedge clk)
		begin
			test_name <= "SETACC2";
			cmd <= cmd_setacc(8'h81, 32'hffffffff);
		end

		/* SETVL */
		@(posedge clk)
		begin
			test_name <= "SETVL2 ";
			cmd <= cmd_setvl(8'h82, 20'h00100);
		end

		/* SETRS */
		@(posedge clk)
		begin
			test_name <= "SETRS2 ";
			cmd <= cmd_setrs(8'h83, 38'h1ffffff0);
		end

		/* SETRT */
		@(posedge clk)
		begin
			test_name <= "SETRT2 ";
			cmd <= cmd_setrt(8'h84, 38'h2ffffff0);
		end

		/* SETRD */
		@(posedge clk)
		begin
			test_name <= "SETRD2 ";
			cmd <= cmd_setrd(8'h85, 38'h3ffffff0);
		end

		/* SETEN */
		@(posedge clk)
		begin
			test_name <= "SETEN2 ";
			cmd <= cmd_seten(8'h86, 1'b1);
		end

		/* PROD */
		@(posedge clk)
		begin
			test_name <= "PROD2  ";
			cmd <= cmd_prod(8'h81);
		end

		/* STORE */
		@(posedge clk)
		begin
			test_name <= "STORE2 ";
			cmd <= cmd_store(8'h81);
		end


		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU2  ";
			cmd <= cmd_relu(8'h81);
		end

		/* LRELU */
		@(posedge clk)
		begin
			test_name <= "LRELU2 ";
			cmd <= cmd_lrelu(8'h81, 7'h4);
		end


		/*** Instructions with ReLU type violations ***/

		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU3  ";
			cmd <= cmd_af_generic(CU_CMD_ACTF, 8'h00, 3'b0,
				6'h1f, 42'h0);
		end


		/*** Valid instructions for different VPUs ***/

		/* SETACC */
		@(posedge clk)
		begin
			test_name <= "SETACC4";
			cmd <= cmd_setacc(8'b00000_001, 32'hffffffff);
		end

		/* SETVL */
		@(posedge clk)
		begin
			test_name <= "SETVL4 ";
			cmd <= cmd_setvl(8'b00001_010, 20'h00100);
		end

		/* SETRS */
		@(posedge clk)
		begin
			test_name <= "SETRS4 ";
			cmd <= cmd_setrs(8'b00010_011, 38'h1ffffff0);
		end

		/* SETRT */
		@(posedge clk)
		begin
			test_name <= "SETRT4 ";
			cmd <= cmd_setrt(8'b00011_100, 38'h2ffffff0);
		end

		/* SETRD */
		@(posedge clk)
		begin
			test_name <= "SETRD4 ";
			cmd <= cmd_setrd(8'b00000_101, 38'h3ffffff0);
		end

		/* SETEN */
		@(posedge clk)
		begin
			test_name <= "SETEN4 ";
			cmd <= cmd_seten(8'b00001_110, 1'b1);
		end

		/* PROD */
		@(posedge clk)
		begin
			test_name <= "PROD4  ";
			cmd <= cmd_prod(8'b00010_001);
		end

		/* STORE */
		@(posedge clk)
		begin
			test_name <= "STORE4 ";
			cmd <= cmd_store(8'b00011_001);
		end

		/* RELU */
		@(posedge clk)
		begin
			test_name <= "RELU4  ";
			cmd <= cmd_relu(8'b00000_001);
		end

		/* LRELU */
		@(posedge clk)
		begin
			test_name <= "LRELU4 ";
			cmd <= cmd_lrelu(8'b00001_001, 7'h4);
		end


		#500 $finish;
	end


	/* Command decoder */
	vxe_cu_cmd_decoder #(
		.VPUS_NR(4),
		.VERIFY_FMT(1)
	) decoder(
		.i_cmd(cmd),
		.o_dec_err(dec_err),
		.o_cu_cmd(cu_cmd),
		.o_cu_nop(cu_nop),
		.o_cu_sync(cu_sync),
		.o_cu_sync_stop(cu_sync_stop),
		.o_cu_sync_intr(cu_sync_intr),
		.o_vpu_cmd(vpu_cmd),
		.o_vpu_mask(vpu_mask),
		.o_vpu_op(vpu_op),
		.o_vpu_th(vpu_th),
		.o_vpu_pl(vpu_pl)
	);


endmodule /* tb_vxe_cu_cmd_decoder */
