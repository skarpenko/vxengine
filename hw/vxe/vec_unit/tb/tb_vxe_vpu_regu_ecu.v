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
 * Testbench for VxE VPU register update execution unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_regu_ecu();
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
	/* Register file interface */
	wire [2:0]	regu_th;
	wire [2:0]	regu_ridx;
	wire		regu_wr_en;
	wire [37:0]	regu_data;
	/* Register values */
	wire [31:0]	out_th0_acc;
	wire [19:0]	out_th0_vl;
	wire		out_th0_en;
	wire [37:0]	out_th0_rs;
	wire [37:0]	out_th0_rt;
	wire [37:0]	out_th0_rd;
	wire [31:0]	out_th1_acc;
	wire [19:0]	out_th1_vl;
	wire		out_th1_en;
	wire [37:0]	out_th1_rs;
	wire [37:0]	out_th1_rt;
	wire [37:0]	out_th1_rd;
	wire [31:0]	out_th2_acc;
	wire [19:0]	out_th2_vl;
	wire		out_th2_en;
	wire [37:0]	out_th2_rs;
	wire [37:0]	out_th2_rt;
	wire [37:0]	out_th2_rd;
	wire [31:0]	out_th3_acc;
	wire [19:0]	out_th3_vl;
	wire		out_th3_en;
	wire [37:0]	out_th3_rs;
	wire [37:0]	out_th3_rt;
	wire [37:0]	out_th3_rd;
	wire [31:0]	out_th4_acc;
	wire [19:0]	out_th4_vl;
	wire		out_th4_en;
	wire [37:0]	out_th4_rs;
	wire [37:0]	out_th4_rt;
	wire [37:0]	out_th4_rd;
	wire [31:0]	out_th5_acc;
	wire [19:0]	out_th5_vl;
	wire		out_th5_en;
	wire [37:0]	out_th5_rs;
	wire [37:0]	out_th5_rt;
	wire [37:0]	out_th5_rd;
	wire [31:0]	out_th6_acc;
	wire [19:0]	out_th6_vl;
	wire		out_th6_en;
	wire [37:0]	out_th6_rs;
	wire [37:0]	out_th6_rt;
	wire [37:0]	out_th6_rd;
	wire [31:0]	out_th7_acc;
	wire [19:0]	out_th7_vl;
	wire		out_th7_en;
	wire [37:0]	out_th7_rs;
	wire [37:0]	out_th7_rt;
	wire [37:0]	out_th7_rd;


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


	integer i;

	initial
	begin : main_test
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_regu_ecu);

		clk = 1'b1;
		nrst = 1'b0;
		disp = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk();
		/***********************************************************/

		/* Loop over threads */
		for(i = 0; i < 8; i = i + 1)
		begin
			/** SETACC **/
			@(posedge clk)
			begin
				disp <= 1'b1;
				cmd_op <= CU_CMD_SETACC;
				cmd_th <= i;
				cmd_pl <= 48'hABCD_0000_1010;
			end
			@(posedge clk) disp <= 1'b0;
			wait_pos_clk();


			/** SETVL **/
			@(posedge clk)
			begin
				disp <= 1'b1;
				cmd_op <= CU_CMD_SETVL;
				cmd_th <= i;
				cmd_pl <= 48'hABCD_0001_0000;
			end
			@(posedge clk) disp <= 1'b0;
			wait_pos_clk();


			/** SETEN **/
			@(posedge clk)
			begin
				disp <= 1'b1;
				cmd_op <= CU_CMD_SETEN;
				cmd_th <= i;
				cmd_pl <= 48'hABCD_0002_0001;
			end
			@(posedge clk) disp <= 1'b0;
			wait_pos_clk();


			/** SETRS **/
			@(posedge clk)
			begin
				disp <= 1'b1;
				cmd_op <= CU_CMD_SETRS;
				cmd_th <= i;
				cmd_pl <= 48'hABCD_0003_0000;
			end
			@(posedge clk) disp <= 1'b0;
			wait_pos_clk();


			/** SETRT **/
			@(posedge clk)
			begin
				disp <= 1'b1;
				cmd_op <= CU_CMD_SETRT;
				cmd_th <= i;
				cmd_pl <= 48'hABCD_0004_0000;
			end
			@(posedge clk) disp <= 1'b0;
			wait_pos_clk();


			/** SETRD **/
			@(posedge clk)
			begin
				disp <= 1'b1;
				cmd_op <= CU_CMD_SETRD;
				cmd_th <= i;
				cmd_pl <= 48'hABCD_0005_0000;
			end
			@(posedge clk) disp <= 1'b0;
			wait_pos_clk();


			/** PROD (invalid case) **/
			@(posedge clk)
			begin
				disp <= 1'b1;
				cmd_op <= CU_CMD_PROD;
				cmd_th <= i;
				cmd_pl <= 48'hABCD_0006_0000;
			end
			@(posedge clk) disp <= 1'b0;
			wait_pos_clk();
		end


		#500 $finish;
	end



	/* Register update unit */
	vxe_vpu_regu_ecu vpu_regu(
		.clk(clk),
		.nrst(nrst),
		.i_disp(disp),
		.o_done(done),
		.i_cmd_op(cmd_op),
		.i_cmd_th(cmd_th),
		.i_cmd_pl(cmd_pl),
		.o_th(regu_th),
		.o_ridx(regu_ridx),
		.o_wr_en(regu_wr_en),
		.o_data(regu_data)
	);


	/* Register file */
	vxe_vpu_rf vpu_rf(
		.clk(clk),
		.nrst(nrst),
		.i_regu_cmd(1'b1),
		.i_regu_th(regu_th),
		.i_regu_ridx(regu_ridx),
		.i_regu_wr_en(regu_wr_en),
		.i_regu_data(regu_data),
		.i_prod_cmd(1'b0),
		.i_prod_th(3'b0),
		.i_prod_ridx(3'b0),
		.i_prod_wr_en(1'b0),
		.i_prod_data(38'b0),
		.i_actf_cmd(1'b0),
		.i_actf_th(3'b0),
		.i_actf_ridx(3'b0),
		.i_actf_wr_en(1'b0),
		.i_actf_data(38'b0),
		.out_th0_acc(out_th0_acc),
		.out_th0_vl(out_th0_vl),
		.out_th0_en(out_th0_en),
		.out_th0_rs(out_th0_rs),
		.out_th0_rt(out_th0_rt),
		.out_th0_rd(out_th0_rd),
		.out_th1_acc(out_th1_acc),
		.out_th1_vl(out_th1_vl),
		.out_th1_en(out_th1_en),
		.out_th1_rs(out_th1_rs),
		.out_th1_rt(out_th1_rt),
		.out_th1_rd(out_th1_rd),
		.out_th2_acc(out_th2_acc),
		.out_th2_vl(out_th2_vl),
		.out_th2_en(out_th2_en),
		.out_th2_rs(out_th2_rs),
		.out_th2_rt(out_th2_rt),
		.out_th2_rd(out_th2_rd),
		.out_th3_acc(out_th3_acc),
		.out_th3_vl(out_th3_vl),
		.out_th3_en(out_th3_en),
		.out_th3_rs(out_th3_rs),
		.out_th3_rt(out_th3_rt),
		.out_th3_rd(out_th3_rd),
		.out_th4_acc(out_th4_acc),
		.out_th4_vl(out_th4_vl),
		.out_th4_en(out_th4_en),
		.out_th4_rs(out_th4_rs),
		.out_th4_rt(out_th4_rt),
		.out_th4_rd(out_th4_rd),
		.out_th5_acc(out_th5_acc),
		.out_th5_vl(out_th5_vl),
		.out_th5_en(out_th5_en),
		.out_th5_rs(out_th5_rs),
		.out_th5_rt(out_th5_rt),
		.out_th5_rd(out_th5_rd),
		.out_th6_acc(out_th6_acc),
		.out_th6_vl(out_th6_vl),
		.out_th6_en(out_th6_en),
		.out_th6_rs(out_th6_rs),
		.out_th6_rt(out_th6_rt),
		.out_th6_rd(out_th6_rd),
		.out_th7_acc(out_th7_acc),
		.out_th7_vl(out_th7_vl),
		.out_th7_en(out_th7_en),
		.out_th7_rs(out_th7_rs),
		.out_th7_rt(out_th7_rt),
		.out_th7_rd(out_th7_rd)
	);


endmodule /* tb_vxe_vpu_regu_ecu */
