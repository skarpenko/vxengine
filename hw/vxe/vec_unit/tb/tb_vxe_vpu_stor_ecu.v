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
 * Testbench for VxE VPU store execution control unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_stor_ecu();
`include "vxe_ctrl_unit_cmds.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Dispatch interface */
	reg		disp;
	wire		done;
	reg [4:0]	cmd_op;
	reg [2:0]	cmd_th;
	reg [47:0]	cmd_pl;
	/* Execution unit interface */
	wire		eu_start;
	reg		eu_busy;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask

	task wait_pos_clk4;
	begin
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
	end
	endtask

	task wait_pos_clk8;
	begin
		wait_pos_clk4();
		wait_pos_clk4();
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_stor_ecu);

		clk = 1'b1;
		nrst = 1'b0;
		disp = 1'b0;
		eu_busy = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk();
		/***********************************************************/

		/** Dispatch store **/
		@(posedge clk)
		begin
			disp <= 1'b1;
			cmd_op <= CU_CMD_STORE;
			cmd_th <= 3'b000; /* Ignored */
			cmd_pl <= 48'b000; /* Ignored */
		end
		@(posedge clk) disp <= 1'b0;
		@(posedge clk) eu_busy <= 1'b1;
		wait_pos_clk8();
		@(posedge clk) eu_busy <= 1'b0;
		wait_pos_clk8();


		wait_pos_clk4();


		/** Wrong command **/
		@(posedge clk)
		begin
			disp <= 1'b1;
			cmd_op <= CU_CMD_PROD;
			cmd_th <= 3'b000; /* Ignored */
			cmd_pl <= 48'b000; /* Ignored */
		end
		@(posedge clk) disp <= 1'b0;
		@(posedge clk) eu_busy <= 1'b1;
		wait_pos_clk8();
		@(posedge clk) eu_busy <= 1'b0;
		wait_pos_clk8();


		#500 $finish;
	end



	/* Execution control unit */
	vxe_vpu_stor_ecu stor_ecu(
		.clk(clk),
		.nrst(nrst),
		.i_disp(disp),
		.o_done(done),
		.i_cmd_op(cmd_op),
		.i_cmd_th(cmd_th),
		.i_cmd_pl(cmd_pl),
		.o_eu_start(eu_start),
		.i_eu_busy(eu_busy)
	);


endmodule /* tb_vxe_vpu_stor_ecu */
