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
 * Testbench for VxE VPU register file
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_rf();
`include "vxe_vpu_regidx_params.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* RF write interface */
	reg		regu_cmd;
	reg [2:0]	regu_th;
	reg [2:0]	regu_ridx;
	reg		regu_wr_en;
	reg [37:0]	regu_data;
	reg		prod_cmd;
	reg [2:0]	prod_th;
	reg [2:0]	prod_ridx;
	reg		prod_wr_en;
	reg [37:0]	prod_data;
	reg		actf_cmd;
	reg [2:0]	actf_th;
	reg [2:0]	actf_ridx;
	reg		actf_wr_en;
	reg [37:0]	actf_data;
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

	/** Testbench specific **/
	reg [0:55]	test_name;	/* Test name, for ex.: Test_01 */


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	integer i;
	initial
	begin : test
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_rf);

		clk = 1'b1;
		nrst = 1'b0;
		regu_cmd = 1'b0;
		regu_wr_en = 1'b0;
		prod_cmd = 1'b0;
		prod_wr_en = 1'b0;
		actf_cmd = 1'b0;
		actf_wr_en = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk();
		/***********************************************************/

		wait_pos_clk();


		/** Register update path test **/
		@(posedge clk)
			test_name <= "regu_01";
		for(i = 0; i < 8; i = i + 1)
		begin
			@(posedge clk)
			begin
				regu_cmd <= 1'b1;
				regu_th <= i;
				regu_ridx <= VPU_REG_IDX_ACC;
				regu_wr_en <= 1'b1;
				regu_data <= 38'h00001;
			end
			@(posedge clk) regu_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				regu_cmd <= 1'b1;
				regu_th <= i;
				regu_ridx <= VPU_REG_IDX_VL;
				regu_wr_en <= 1'b1;
				regu_data <= 38'h00002;
			end
			@(posedge clk) regu_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				regu_cmd <= 1'b1;
				regu_th <= i;
				regu_ridx <= VPU_REG_IDX_EN;
				regu_wr_en <= 1'b1;
				regu_data <= 38'h00001;
			end
			@(posedge clk) regu_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				regu_cmd <= 1'b1;
				regu_th <= i;
				regu_ridx <= VPU_REG_IDX_EN;
				regu_wr_en <= 1'b1;
				regu_data <= 38'h00000;
			end
			@(posedge clk) regu_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				regu_cmd <= 1'b1;
				regu_th <= i;
				regu_ridx <= VPU_REG_IDX_RS;
				regu_wr_en <= 1'b1;
				regu_data <= 38'h00003;
			end
			@(posedge clk) regu_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				regu_cmd <= 1'b1;
				regu_th <= i;
				regu_ridx <= VPU_REG_IDX_RT;
				regu_wr_en <= 1'b1;
				regu_data <= 38'h00004;
			end
			@(posedge clk) regu_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				regu_cmd <= 1'b1;
				regu_th <= i;
				regu_ridx <= VPU_REG_IDX_RD;
				regu_wr_en <= 1'b1;
				regu_data <= 38'h00005;
			end
			@(posedge clk) regu_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();
		end
		@(posedge clk) regu_cmd <= 1'b0;


		/** Product path test **/
		@(posedge clk)
			test_name <= "prod_01";
		for(i = 0; i < 8; i = i + 1)
		begin
			@(posedge clk)
			begin
				prod_cmd <= 1'b1;
				prod_th <= i;
				prod_ridx <= VPU_REG_IDX_ACC;
				prod_wr_en <= 1'b1;
				prod_data <= 38'h00011;
			end
			@(posedge clk) prod_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				prod_cmd <= 1'b1;
				prod_th <= i;
				prod_ridx <= VPU_REG_IDX_VL;
				prod_wr_en <= 1'b1;
				prod_data <= 38'h00012;
			end
			@(posedge clk) prod_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				prod_cmd <= 1'b1;
				prod_th <= i;
				prod_ridx <= VPU_REG_IDX_EN;
				prod_wr_en <= 1'b1;
				prod_data <= 38'h00001;
			end
			@(posedge clk) prod_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				prod_cmd <= 1'b1;
				prod_th <= i;
				prod_ridx <= VPU_REG_IDX_EN;
				prod_wr_en <= 1'b1;
				prod_data <= 38'h00000;
			end
			@(posedge clk) prod_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				prod_cmd <= 1'b1;
				prod_th <= i;
				prod_ridx <= VPU_REG_IDX_RS;
				prod_wr_en <= 1'b1;
				prod_data <= 38'h00013;
			end
			@(posedge clk) prod_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				prod_cmd <= 1'b1;
				prod_th <= i;
				prod_ridx <= VPU_REG_IDX_RT;
				prod_wr_en <= 1'b1;
				prod_data <= 38'h00014;
			end
			@(posedge clk) prod_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				prod_cmd <= 1'b1;
				prod_th <= i;
				prod_ridx <= VPU_REG_IDX_RD;
				prod_wr_en <= 1'b1;
				prod_data <= 38'h00015;
			end
			@(posedge clk) prod_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();
		end
		@(posedge clk) prod_cmd <= 1'b0;


		/** Activation function path test **/
		@(posedge clk)
			test_name <= "actf_01";
		for(i = 0; i < 8; i = i + 1)
		begin
			@(posedge clk)
			begin
				actf_cmd <= 1'b1;
				actf_th <= i;
				actf_ridx <= VPU_REG_IDX_ACC;
				actf_wr_en <= 1'b1;
				actf_data <= 38'h00021;
			end
			@(posedge clk) actf_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				actf_cmd <= 1'b1;
				actf_th <= i;
				actf_ridx <= VPU_REG_IDX_VL;
				actf_wr_en <= 1'b1;
				actf_data <= 38'h00022;
			end
			@(posedge clk) actf_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				actf_cmd <= 1'b1;
				actf_th <= i;
				actf_ridx <= VPU_REG_IDX_EN;
				actf_wr_en <= 1'b1;
				actf_data <= 38'h00001;
			end
			@(posedge clk) actf_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				actf_cmd <= 1'b1;
				actf_th <= i;
				actf_ridx <= VPU_REG_IDX_EN;
				actf_wr_en <= 1'b1;
				actf_data <= 38'h00000;
			end
			@(posedge clk) actf_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				actf_cmd <= 1'b1;
				actf_th <= i;
				actf_ridx <= VPU_REG_IDX_RS;
				actf_wr_en <= 1'b1;
				actf_data <= 38'h00023;
			end
			@(posedge clk) actf_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				actf_cmd <= 1'b1;
				actf_th <= i;
				actf_ridx <= VPU_REG_IDX_RT;
				actf_wr_en <= 1'b1;
				actf_data <= 38'h00024;
			end
			@(posedge clk) actf_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();

			@(posedge clk)
			begin
				actf_cmd <= 1'b1;
				actf_th <= i;
				actf_ridx <= VPU_REG_IDX_RD;
				actf_wr_en <= 1'b1;
				actf_data <= 38'h00025;
			end
			@(posedge clk) actf_wr_en <= 1'b0;

			wait_pos_clk();
			wait_pos_clk();
		end
		@(posedge clk) actf_cmd <= 1'b0;


		#500 $finish;
	end


	/* Register file */
	vxe_vpu_rf vpu_rf(
		.clk(clk),
		.nrst(nrst),
		.i_regu_cmd(regu_cmd),
		.i_regu_th(regu_th),
		.i_regu_ridx(regu_ridx),
		.i_regu_wr_en(regu_wr_en),
		.i_regu_data(regu_data),
		.i_prod_cmd(prod_cmd),
		.i_prod_th(prod_th),
		.i_prod_ridx(prod_ridx),
		.i_prod_wr_en(prod_wr_en),
		.i_prod_data(prod_data),
		.i_actf_cmd(actf_cmd),
		.i_actf_th(actf_th),
		.i_actf_ridx(actf_ridx),
		.i_actf_wr_en(actf_wr_en),
		.i_actf_data(actf_data),
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


endmodule /* tb_vxe_vpu_rf */
