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
 * Testbench for VxE VPU FMAC scheduler unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


/* Test groups */
`define TESTS_RS_FIRST		/* Rs arrives first */
`define TESTS_RT_FIRST		/* Rs arrives first */
`define TESTS_RSRT_BOTH		/* Rs and Rt arrive at the same time */
`define TESTS_ALL_THREADS	/* Rs and Rt arrive at the same time for all threads */
`define TESTS_ERR_FLUSH		/* FLUSH on error */


module tb_vxe_vpu_prod_eu_fmac();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Control interface */
	reg		err_flush;
	wire		busy;
	/* Operand FIFO interface */
	reg [31:0]	rs0_opd_data;
	wire		rs0_opd_rd;
	reg		rs0_opd_vld;
	reg [31:0]	rt0_opd_data;
	wire		rt0_opd_rd;
	reg		rt0_opd_vld;
	reg [31:0]	rs1_opd_data;
	wire		rs1_opd_rd;
	reg		rs1_opd_vld;
	reg [31:0]	rt1_opd_data;
	wire		rt1_opd_rd;
	reg		rt1_opd_vld;
	reg [31:0]	rs2_opd_data;
	wire		rs2_opd_rd;
	reg		rs2_opd_vld;
	reg [31:0]	rt2_opd_data;
	wire		rt2_opd_rd;
	reg		rt2_opd_vld;
	reg [31:0]	rs3_opd_data;
	wire		rs3_opd_rd;
	reg		rs3_opd_vld;
	reg [31:0]	rt3_opd_data;
	wire		rt3_opd_rd;
	reg		rt3_opd_vld;
	reg [31:0]	rs4_opd_data;
	wire		rs4_opd_rd;
	reg		rs4_opd_vld;
	reg [31:0]	rt4_opd_data;
	wire		rt4_opd_rd;
	reg		rt4_opd_vld;
	reg [31:0]	rs5_opd_data;
	wire		rs5_opd_rd;
	reg		rs5_opd_vld;
	reg [31:0]	rt5_opd_data;
	wire		rt5_opd_rd;
	reg		rt5_opd_vld;
	reg [31:0]	rs6_opd_data;
	wire		rs6_opd_rd;
	reg		rs6_opd_vld;
	reg [31:0]	rt6_opd_data;
	wire		rt6_opd_rd;
	reg		rt6_opd_vld;
	reg [31:0]	rs7_opd_data;
	wire		rs7_opd_rd;
	reg		rs7_opd_vld;
	reg [31:0]	rt7_opd_data;
	wire		rt7_opd_rd;
	reg		rt7_opd_vld;
	/* Register file accumulator values */
	wire [31:0]	th0_acc = 32'h2000_0000;
	wire [31:0]	th1_acc = 32'h2000_0001;
	wire [31:0]	th2_acc = 32'h2000_0002;
	wire [31:0]	th3_acc = 32'h2000_0003;
	wire [31:0]	th4_acc = 32'h2000_0004;
	wire [31:0]	th5_acc = 32'h2000_0005;
	wire [31:0]	th6_acc = 32'h2000_0006;
	wire [31:0]	th7_acc = 32'h2000_0007;
	/* Register file write interface */
	wire [2:0]	prod_th;
	wire [2:0]	prod_ridx;
	wire		prod_wr_en;
	wire [37:0]	prod_data;

	/** Testbench specific **/
	reg [0:55]	test_name;		/* Test name, for ex.: Test_01 */


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


	/* Set test name */
	task test;
	input [0:55]	name;
	input integer j;	/* Number of cycles to wait after setting name */
	integer i;
	begin
		@(posedge clk)
			test_name <= name;
		for(i=0; i<j; i++)
			@(posedge clk);
	end
	endtask


	/* Set Rs operand value */
	task set_rs_value;
	input [7:0]	th_mask;	/* Thread mask */
	input [31:0]	value;		/* Operand value */
	begin
		@(posedge clk)
		begin
			rs0_opd_vld <= th_mask[0];
			rs1_opd_vld <= th_mask[1];
			rs2_opd_vld <= th_mask[2];
			rs3_opd_vld <= th_mask[3];
			rs4_opd_vld <= th_mask[4];
			rs5_opd_vld <= th_mask[5];
			rs6_opd_vld <= th_mask[6];
			rs7_opd_vld <= th_mask[7];

			rs0_opd_data <= th_mask[0] ? value : 32'h0000_0000;
			rs1_opd_data <= th_mask[1] ? value : 32'h0000_0000;
			rs2_opd_data <= th_mask[2] ? value : 32'h0000_0000;
			rs3_opd_data <= th_mask[3] ? value : 32'h0000_0000;
			rs4_opd_data <= th_mask[4] ? value : 32'h0000_0000;
			rs5_opd_data <= th_mask[5] ? value : 32'h0000_0000;
			rs6_opd_data <= th_mask[6] ? value : 32'h0000_0000;
			rs7_opd_data <= th_mask[7] ? value : 32'h0000_0000;
		end
		@(posedge clk) ;	/* 1-cycle delay */
		@(posedge clk)
		begin
			rs0_opd_vld <= 1'b0;
			rs1_opd_vld <= 1'b0;
			rs2_opd_vld <= 1'b0;
			rs3_opd_vld <= 1'b0;
			rs4_opd_vld <= 1'b0;
			rs5_opd_vld <= 1'b0;
			rs6_opd_vld <= 1'b0;
			rs7_opd_vld <= 1'b0;
		end
	end
	endtask


	/* Set Rt operand value */
	task set_rt_value;
	input [7:0]	th_mask;	/* Thread mask */
	input [31:0]	value;		/* Operand value */
	begin
		@(posedge clk)
		begin
			rt0_opd_vld <= th_mask[0];
			rt1_opd_vld <= th_mask[1];
			rt2_opd_vld <= th_mask[2];
			rt3_opd_vld <= th_mask[3];
			rt4_opd_vld <= th_mask[4];
			rt5_opd_vld <= th_mask[5];
			rt6_opd_vld <= th_mask[6];
			rt7_opd_vld <= th_mask[7];

			rt0_opd_data <= th_mask[0] ? value : 32'h0000_0000;
			rt1_opd_data <= th_mask[1] ? value : 32'h0000_0000;
			rt2_opd_data <= th_mask[2] ? value : 32'h0000_0000;
			rt3_opd_data <= th_mask[3] ? value : 32'h0000_0000;
			rt4_opd_data <= th_mask[4] ? value : 32'h0000_0000;
			rt5_opd_data <= th_mask[5] ? value : 32'h0000_0000;
			rt6_opd_data <= th_mask[6] ? value : 32'h0000_0000;
			rt7_opd_data <= th_mask[7] ? value : 32'h0000_0000;
		end
		@(posedge clk) ;	/* 1-cycle delay */
		@(posedge clk)
		begin
			rt0_opd_vld <= 1'b0;
			rt1_opd_vld <= 1'b0;
			rt2_opd_vld <= 1'b0;
			rt3_opd_vld <= 1'b0;
			rt4_opd_vld <= 1'b0;
			rt5_opd_vld <= 1'b0;
			rt6_opd_vld <= 1'b0;
			rt7_opd_vld <= 1'b0;
		end
	end
	endtask


	/* Set Rs and Rt operands */
	task set_rsrt_value;
	input [7:0]	th_mask;	/* Thread mask */
	input [31:0]	rs_value;	/* Rs operand value */
	input [31:0]	rt_value;	/* Rt operand value */
	begin
		@(posedge clk)
		begin
			rs0_opd_vld <= th_mask[0];
			rt0_opd_vld <= th_mask[0];
			rs1_opd_vld <= th_mask[1];
			rt1_opd_vld <= th_mask[1];
			rs2_opd_vld <= th_mask[2];
			rt2_opd_vld <= th_mask[2];
			rs3_opd_vld <= th_mask[3];
			rt3_opd_vld <= th_mask[3];
			rs4_opd_vld <= th_mask[4];
			rt4_opd_vld <= th_mask[4];
			rs5_opd_vld <= th_mask[5];
			rt5_opd_vld <= th_mask[5];
			rs6_opd_vld <= th_mask[6];
			rt6_opd_vld <= th_mask[6];
			rs7_opd_vld <= th_mask[7];
			rt7_opd_vld <= th_mask[7];

			rs0_opd_data <= th_mask[0] ? rs_value : 32'h0000_0000;
			rt0_opd_data <= th_mask[0] ? rt_value : 32'h0000_0000;
			rs1_opd_data <= th_mask[1] ? rs_value : 32'h0000_0000;
			rt1_opd_data <= th_mask[1] ? rt_value : 32'h0000_0000;
			rs2_opd_data <= th_mask[2] ? rs_value : 32'h0000_0000;
			rt2_opd_data <= th_mask[2] ? rt_value : 32'h0000_0000;
			rs3_opd_data <= th_mask[3] ? rs_value : 32'h0000_0000;
			rt3_opd_data <= th_mask[3] ? rt_value : 32'h0000_0000;
			rs4_opd_data <= th_mask[4] ? rs_value : 32'h0000_0000;
			rt4_opd_data <= th_mask[4] ? rt_value : 32'h0000_0000;
			rs5_opd_data <= th_mask[5] ? rs_value : 32'h0000_0000;
			rt5_opd_data <= th_mask[5] ? rt_value : 32'h0000_0000;
			rs6_opd_data <= th_mask[6] ? rs_value : 32'h0000_0000;
			rt6_opd_data <= th_mask[6] ? rt_value : 32'h0000_0000;
			rs7_opd_data <= th_mask[7] ? rs_value : 32'h0000_0000;
			rt7_opd_data <= th_mask[7] ? rt_value : 32'h0000_0000;
		end
		@(posedge clk) ;	/* 1-cycle delay */
		@(posedge clk)
		begin
			rs0_opd_vld <= 1'b0;
			rt0_opd_vld <= 1'b0;
			rs1_opd_vld <= 1'b0;
			rt1_opd_vld <= 1'b0;
			rs2_opd_vld <= 1'b0;
			rt2_opd_vld <= 1'b0;
			rs3_opd_vld <= 1'b0;
			rt3_opd_vld <= 1'b0;
			rs4_opd_vld <= 1'b0;
			rt4_opd_vld <= 1'b0;
			rs5_opd_vld <= 1'b0;
			rt5_opd_vld <= 1'b0;
			rs6_opd_vld <= 1'b0;
			rt6_opd_vld <= 1'b0;
			rs7_opd_vld <= 1'b0;
			rt7_opd_vld <= 1'b0;
		end
	end
	endtask



	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_prod_eu_fmac);

		clk = 1'b1;
		nrst = 1'b0;

		err_flush = 1'b0;

		rs0_opd_vld = 1'b0;
		rs0_opd_data = 32'h00000000;
		rt0_opd_vld = 1'b0;
		rt0_opd_data = 32'h00000000;
		rs1_opd_vld = 1'b0;
		rs1_opd_data = 32'h00000000;
		rt1_opd_vld = 1'b0;
		rt1_opd_data = 32'h00000000;
		rs2_opd_vld = 1'b0;
		rs2_opd_data = 32'h00000000;
		rt2_opd_vld = 1'b0;
		rt2_opd_data = 32'h00000000;
		rs3_opd_vld = 1'b0;
		rs3_opd_data = 32'h00000000;
		rt3_opd_vld = 1'b0;
		rt3_opd_data = 32'h00000000;
		rs4_opd_vld = 1'b0;
		rs4_opd_data = 32'h00000000;
		rt4_opd_vld = 1'b0;
		rt4_opd_data = 32'h00000000;
		rs5_opd_vld = 1'b0;
		rs5_opd_data = 32'h00000000;
		rt5_opd_vld = 1'b0;
		rt5_opd_data = 32'h00000000;
		rs6_opd_vld = 1'b0;
		rs6_opd_data = 32'h00000000;
		rt6_opd_vld = 1'b0;
		rt6_opd_data = 32'h00000000;
		rs7_opd_vld = 1'b0;
		rs7_opd_data = 32'h00000000;
		rt7_opd_vld = 1'b0;
		rt7_opd_data = 32'h00000000;


		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(1);
		/***********************************************************/


`ifdef TESTS_RS_FIRST
		/*** Test 00 - Rs data arrives first ****/
		test("Test_00", 0);
		/* Thread 0 */
		set_rs_value(8'b0000_0001, 32'h4000_1000);
		set_rt_value(8'b0000_0001, 32'h4000_2000);
		wait_pos_clk(16);
		/* Thread 1 */
		set_rs_value(8'b0000_0010, 32'h4000_1100);
		set_rt_value(8'b0000_0010, 32'h4000_2100);
		wait_pos_clk(16);
		/* Thread 2 */
		set_rs_value(8'b0000_0100, 32'h4000_1200);
		set_rt_value(8'b0000_0100, 32'h4000_2200);
		wait_pos_clk(16);
		/* Thread 3 */
		set_rs_value(8'b0000_1000, 32'h4000_1300);
		set_rt_value(8'b0000_1000, 32'h4000_2300);
		wait_pos_clk(16);
		/* Thread 4 */
		set_rs_value(8'b0001_0000, 32'h4000_1400);
		set_rt_value(8'b0001_0000, 32'h4000_2400);
		wait_pos_clk(16);
		/* Thread 5 */
		set_rs_value(8'b0010_0000, 32'h4000_1500);
		set_rt_value(8'b0010_0000, 32'h4000_2500);
		wait_pos_clk(16);
		/* Thread 6 */
		set_rs_value(8'b0100_0000, 32'h4000_1600);
		set_rt_value(8'b0100_0000, 32'h4000_2600);
		wait_pos_clk(16);
		/* Thread 7 */
		set_rs_value(8'b1000_0000, 32'h4000_1700);
		set_rt_value(8'b1000_0000, 32'h4000_2700);
		wait_pos_clk(16);
		test("Done_00", 8);
`endif


`ifdef TESTS_RT_FIRST
		/*** Test 01 - Rt data arrives first ****/
		test("Test_01", 0);
		/* Thread 0 */
		set_rt_value(8'b0000_0001, 32'h4000_2000);
		set_rs_value(8'b0000_0001, 32'h4000_1000);
		wait_pos_clk(16);
		/* Thread 1 */
		set_rt_value(8'b0000_0010, 32'h4000_2100);
		set_rs_value(8'b0000_0010, 32'h4000_1100);
		wait_pos_clk(16);
		/* Thread 2 */
		set_rt_value(8'b0000_0100, 32'h4000_2200);
		set_rs_value(8'b0000_0100, 32'h4000_1200);
		wait_pos_clk(16);
		/* Thread 3 */
		set_rt_value(8'b0000_1000, 32'h4000_2300);
		set_rs_value(8'b0000_1000, 32'h4000_1300);
		wait_pos_clk(16);
		/* Thread 4 */
		set_rt_value(8'b0001_0000, 32'h4000_2400);
		set_rs_value(8'b0001_0000, 32'h4000_1400);
		wait_pos_clk(16);
		/* Thread 5 */
		set_rt_value(8'b0010_0000, 32'h4000_2500);
		set_rs_value(8'b0010_0000, 32'h4000_1500);
		wait_pos_clk(16);
		/* Thread 6 */
		set_rt_value(8'b0100_0000, 32'h4000_2600);
		set_rs_value(8'b0100_0000, 32'h4000_1600);
		wait_pos_clk(16);
		/* Thread 7 */
		set_rt_value(8'b1000_0000, 32'h4000_2700);
		set_rs_value(8'b1000_0000, 32'h4000_1700);
		wait_pos_clk(16);
		test("Done_01", 8);
`endif


`ifdef TESTS_RSRT_BOTH
		/*** Test 02 - Rs and Rt data arrive at the same time ****/
		test("Test_02", 0);
		/* Thread 0 */
		set_rsrt_value(8'b0000_0001, 32'h4000_1000, 32'h4000_2000);
		wait_pos_clk(16);
		/* Thread 1 */
		set_rsrt_value(8'b0000_0010, 32'h4000_1100, 32'h4000_2100);
		wait_pos_clk(16);
		/* Thread 2 */
		set_rsrt_value(8'b0000_0100, 32'h4000_1200, 32'h4000_2200);
		wait_pos_clk(16);
		/* Thread 3 */
		set_rsrt_value(8'b0000_1000, 32'h4000_1300, 32'h4000_2300);
		wait_pos_clk(16);
		/* Thread 4 */
		set_rsrt_value(8'b0001_0000, 32'h4000_1400, 32'h4000_2400);
		wait_pos_clk(16);
		/* Thread 5 */
		set_rsrt_value(8'b0010_0000, 32'h4000_1500, 32'h4000_2500);
		wait_pos_clk(16);
		/* Thread 6 */
		set_rsrt_value(8'b0100_0000, 32'h4000_1600, 32'h4000_2600);
		wait_pos_clk(16);
		/* Thread 7 */
		set_rsrt_value(8'b1000_0000, 32'h4000_1700, 32'h4000_2700);
		wait_pos_clk(16);
		test("Done_02", 8);
`endif


`ifdef TESTS_ALL_THREADS
		/*** Test 03 - Rs and Rt data arrive for all threads ****/
		test("Test_03", 0);
		@(posedge clk)
		begin
			rs0_opd_vld <= 1'b1;
			rt0_opd_vld <= 1'b1;
			rs1_opd_vld <= 1'b1;
			rt1_opd_vld <= 1'b1;
			rs2_opd_vld <= 1'b1;
			rt2_opd_vld <= 1'b1;
			rs3_opd_vld <= 1'b1;
			rt3_opd_vld <= 1'b1;
			rs4_opd_vld <= 1'b1;
			rt4_opd_vld <= 1'b1;
			rs5_opd_vld <= 1'b1;
			rt5_opd_vld <= 1'b1;
			rs6_opd_vld <= 1'b1;
			rt6_opd_vld <= 1'b1;
			rs7_opd_vld <= 1'b1;
			rt7_opd_vld <= 1'b1;

			rs0_opd_data <= 32'h4000_1000;
			rt0_opd_data <= 32'h4000_2000;
			rs1_opd_data <= 32'h4000_1100;
			rt1_opd_data <= 32'h4000_2100;
			rs2_opd_data <= 32'h4000_1200;
			rt2_opd_data <= 32'h4000_2200;
			rs3_opd_data <= 32'h4000_1300;
			rt3_opd_data <= 32'h4000_2300;
			rs4_opd_data <= 32'h4000_1400;
			rt4_opd_data <= 32'h4000_2400;
			rs5_opd_data <= 32'h4000_1500;
			rt5_opd_data <= 32'h4000_2500;
			rs6_opd_data <= 32'h4000_1600;
			rt6_opd_data <= 32'h4000_2600;
			rs7_opd_data <= 32'h4000_1700;
			rt7_opd_data <= 32'h4000_2700;
		end
		@(posedge clk) ;	/* 1-cycle delay */
		@(posedge clk)
		begin
			rs0_opd_vld <= 1'b0;
			rt0_opd_vld <= 1'b0;
			rs1_opd_vld <= 1'b0;
			rt1_opd_vld <= 1'b0;
			rs2_opd_vld <= 1'b0;
			rt2_opd_vld <= 1'b0;
			rs3_opd_vld <= 1'b0;
			rt3_opd_vld <= 1'b0;
			rs4_opd_vld <= 1'b0;
			rt4_opd_vld <= 1'b0;
			rs5_opd_vld <= 1'b0;
			rt5_opd_vld <= 1'b0;
			rs6_opd_vld <= 1'b0;
			rt6_opd_vld <= 1'b0;
			rs7_opd_vld <= 1'b0;
			rt7_opd_vld <= 1'b0;
		end
		wait_pos_clk(16);
		test("Done_03", 8);
`endif


`ifdef TESTS_ERR_FLUSH
		/*** Test 04 - flush on error ****/
		test("Test_04", 0);
		/* Thread 0 - Rs */
		set_rs_value(8'b0000_0001, 32'h4000_1000);
		/* Thread 1 - Rs */
		set_rs_value(8'b0000_0010, 32'h4000_1100);
		/* Thread 2 - Rs */
		set_rs_value(8'b0000_0100, 32'h4000_1200);
		/* Thread 3 - Rs */
		set_rs_value(8'b0000_1000, 32'h4000_1300);
		/* Thread 4 - Rs */
		set_rs_value(8'b0001_0000, 32'h4000_1400);
		/* Thread 5 - Rs */
		set_rs_value(8'b0010_0000, 32'h4000_1500);
		/* Thread 6 - Rs */
		set_rs_value(8'b0100_0000, 32'h4000_1600);
		/* Thread 7 - Rs */
		set_rs_value(8'b1000_0000, 32'h4000_1700);

		wait_pos_clk(16);
		@(posedge clk) err_flush <= 1'b1;
		@(posedge clk) err_flush <= 1'b0;
		wait_pos_clk(16);

		/* Thread 1 - Rt */
		set_rt_value(8'b0000_0001, 32'h4000_2000);
		/* Thread 2 - Rt */
		set_rt_value(8'b0000_0010, 32'h4000_2100);
		/* Thread 3 - Rt */
		set_rt_value(8'b0000_0100, 32'h4000_2200);
		/* Thread 4 - Rt */
		set_rt_value(8'b0000_1000, 32'h4000_2300);
		/* Thread 5 - Rt */
		set_rt_value(8'b0001_0000, 32'h4000_2400);
		/* Thread 6 - Rt */
		set_rt_value(8'b0010_0000, 32'h4000_2500);
		/* Thread 7 - Rt */
		set_rt_value(8'b0100_0000, 32'h4000_2600);
		/* Thread 8 - Rt */
		set_rt_value(8'b1000_0000, 32'h4000_2700);

		wait_pos_clk(16);
		@(posedge clk) err_flush <= 1'b1;
		@(posedge clk) err_flush <= 1'b0;
		wait_pos_clk(16);

		test("Done_04", 8);
`endif


		#500 $finish;
	end



	/* FMAC scheduler unit */
	vxe_vpu_prod_eu_fmac #(
		.IN_OP_DEPTH_POW2(2)
	) fmac_sched (
		.clk(clk),
		.nrst(nrst),
		.i_err_flush(err_flush),
		.o_busy(busy),
		.i_rs0_opd_data(rs0_opd_data),
		.o_rs0_opd_rd(rs0_opd_rd),
		.i_rs0_opd_vld(rs0_opd_vld),
		.i_rt0_opd_data(rt0_opd_data),
		.o_rt0_opd_rd(rt0_opd_rd),
		.i_rt0_opd_vld(rt0_opd_vld),
		.i_rs1_opd_data(rs1_opd_data),
		.o_rs1_opd_rd(rs1_opd_rd),
		.i_rs1_opd_vld(rs1_opd_vld),
		.i_rt1_opd_data(rt1_opd_data),
		.o_rt1_opd_rd(rt1_opd_rd),
		.i_rt1_opd_vld(rt1_opd_vld),
		.i_rs2_opd_data(rs2_opd_data),
		.o_rs2_opd_rd(rs2_opd_rd),
		.i_rs2_opd_vld(rs2_opd_vld),
		.i_rt2_opd_data(rt2_opd_data),
		.o_rt2_opd_rd(rt2_opd_rd),
		.i_rt2_opd_vld(rt2_opd_vld),
		.i_rs3_opd_data(rs3_opd_data),
		.o_rs3_opd_rd(rs3_opd_rd),
		.i_rs3_opd_vld(rs3_opd_vld),
		.i_rt3_opd_data(rt3_opd_data),
		.o_rt3_opd_rd(rt3_opd_rd),
		.i_rt3_opd_vld(rt3_opd_vld),
		.i_rs4_opd_data(rs4_opd_data),
		.o_rs4_opd_rd(rs4_opd_rd),
		.i_rs4_opd_vld(rs4_opd_vld),
		.i_rt4_opd_data(rt4_opd_data),
		.o_rt4_opd_rd(rt4_opd_rd),
		.i_rt4_opd_vld(rt4_opd_vld),
		.i_rs5_opd_data(rs5_opd_data),
		.o_rs5_opd_rd(rs5_opd_rd),
		.i_rs5_opd_vld(rs5_opd_vld),
		.i_rt5_opd_data(rt5_opd_data),
		.o_rt5_opd_rd(rt5_opd_rd),
		.i_rt5_opd_vld(rt5_opd_vld),
		.i_rs6_opd_data(rs6_opd_data),
		.o_rs6_opd_rd(rs6_opd_rd),
		.i_rs6_opd_vld(rs6_opd_vld),
		.i_rt6_opd_data(rt6_opd_data),
		.o_rt6_opd_rd(rt6_opd_rd),
		.i_rt6_opd_vld(rt6_opd_vld),
		.i_rs7_opd_data(rs7_opd_data),
		.o_rs7_opd_rd(rs7_opd_rd),
		.i_rs7_opd_vld(rs7_opd_vld),
		.i_rt7_opd_data(rt7_opd_data),
		.o_rt7_opd_rd(rt7_opd_rd),
		.i_rt7_opd_vld(rt7_opd_vld),
		.i_th0_acc(th0_acc),
		.i_th1_acc(th1_acc),
		.i_th2_acc(th2_acc),
		.i_th3_acc(th3_acc),
		.i_th4_acc(th4_acc),
		.i_th5_acc(th5_acc),
		.i_th6_acc(th6_acc),
		.i_th7_acc(th7_acc),
		.o_prod_th(prod_th),
		.o_prod_ridx(prod_ridx),
		.o_prod_wr_en(prod_wr_en),
		.o_prod_data(prod_data)
	);



endmodule /* tb_vxe_vpu_prod_eu_fmac */
