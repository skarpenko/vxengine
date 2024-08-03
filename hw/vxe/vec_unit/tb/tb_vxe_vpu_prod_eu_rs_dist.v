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
 * Testbench for VxE VPU responses distributor unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


/* Test groups */
`define TESTS_SINGLE_RESP	/* Single response pass */
`define TESTS_CLOGGED_PATH	/* Receive path clogged */
`define TESTS_LOWORD_RESP	/* Low word valid response */
`define TESTS_HIWORD_RESP	/* High word valid response */



module tb_vxe_vpu_prod_eu_rs_dist();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	genvar i, j;	/* Generator block vars */

	reg		clk;
	reg		nrst;
	/* Control interface */
	wire		busy;
	/* LSU interface */
	reg		rrs_vld;
	wire		rrs_rd;
	reg [2:0]	rrs_th;
	reg		rrs_arg;
	reg [63:0]	rrs_data;
	/* Write enable FIFO interface */
	reg [1:0]	rrs_rs0_we_mask;
	wire		rrs_rs0_we_rd;
	reg		rrs_rs0_we_vld;
	reg [1:0]	rrs_rt0_we_mask;
	wire		rrs_rt0_we_rd;
	reg		rrs_rt0_we_vld;
	reg [1:0]	rrs_rs1_we_mask;
	wire		rrs_rs1_we_rd;
	reg		rrs_rs1_we_vld;
	reg [1:0]	rrs_rt1_we_mask;
	wire		rrs_rt1_we_rd;
	reg		rrs_rt1_we_vld;
	reg [1:0]	rrs_rs2_we_mask;
	wire		rrs_rs2_we_rd;
	reg		rrs_rs2_we_vld;
	reg [1:0]	rrs_rt2_we_mask;
	wire		rrs_rt2_we_rd;
	reg		rrs_rt2_we_vld;
	reg [1:0]	rrs_rs3_we_mask;
	wire		rrs_rs3_we_rd;
	reg		rrs_rs3_we_vld;
	reg [1:0]	rrs_rt3_we_mask;
	wire		rrs_rt3_we_rd;
	reg		rrs_rt3_we_vld;
	reg [1:0]	rrs_rs4_we_mask;
	wire		rrs_rs4_we_rd;
	reg		rrs_rs4_we_vld;
	reg [1:0]	rrs_rt4_we_mask;
	wire		rrs_rt4_we_rd;
	reg		rrs_rt4_we_vld;
	reg [1:0]	rrs_rs5_we_mask;
	wire		rrs_rs5_we_rd;
	reg		rrs_rs5_we_vld;
	reg [1:0]	rrs_rt5_we_mask;
	wire		rrs_rt5_we_rd;
	reg		rrs_rt5_we_vld;
	reg [1:0]	rrs_rs6_we_mask;
	wire		rrs_rs6_we_rd;
	reg		rrs_rs6_we_vld;
	reg [1:0]	rrs_rt6_we_mask;
	wire		rrs_rt6_we_rd;
	reg		rrs_rt6_we_vld;
	reg [1:0]	rrs_rs7_we_mask;
	wire		rrs_rs7_we_rd;
	reg		rrs_rs7_we_vld;
	reg [1:0]	rrs_rt7_we_mask;
	wire		rrs_rt7_we_rd;
	reg		rrs_rt7_we_vld;
	/* Operand FIFO interface */
	wire [63:0]	f21_rs0_opd_data;
	wire [1:0]	f21_rs0_opd_wr;
	wire		f21_rs0_opd_rdy;
	wire [63:0]	f21_rt0_opd_data;
	wire [1:0]	f21_rt0_opd_wr;
	wire		f21_rt0_opd_rdy;
	wire [63:0]	f21_rs1_opd_data;
	wire [1:0]	f21_rs1_opd_wr;
	wire		f21_rs1_opd_rdy;
	wire [63:0]	f21_rt1_opd_data;
	wire [1:0]	f21_rt1_opd_wr;
	wire		f21_rt1_opd_rdy;
	wire [63:0]	f21_rs2_opd_data;
	wire [1:0]	f21_rs2_opd_wr;
	wire		f21_rs2_opd_rdy;
	wire [63:0]	f21_rt2_opd_data;
	wire [1:0]	f21_rt2_opd_wr;
	wire		f21_rt2_opd_rdy;
	wire [63:0]	f21_rs3_opd_data;
	wire [1:0]	f21_rs3_opd_wr;
	wire		f21_rs3_opd_rdy;
	wire [63:0]	f21_rt3_opd_data;
	wire [1:0]	f21_rt3_opd_wr;
	wire		f21_rt3_opd_rdy;
	wire [63:0]	f21_rs4_opd_data;
	wire [1:0]	f21_rs4_opd_wr;
	wire		f21_rs4_opd_rdy;
	wire [63:0]	f21_rt4_opd_data;
	wire [1:0]	f21_rt4_opd_wr;
	wire		f21_rt4_opd_rdy;
	wire [63:0]	f21_rs5_opd_data;
	wire [1:0]	f21_rs5_opd_wr;
	wire		f21_rs5_opd_rdy;
	wire [63:0]	f21_rt5_opd_data;
	wire [1:0]	f21_rt5_opd_wr;
	wire		f21_rt5_opd_rdy;
	wire [63:0]	f21_rs6_opd_data;
	wire [1:0]	f21_rs6_opd_wr;
	wire		f21_rs6_opd_rdy;
	wire [63:0]	f21_rt6_opd_data;
	wire [1:0]	f21_rt6_opd_wr;
	wire		f21_rt6_opd_rdy;
	wire [63:0]	f21_rs7_opd_data;
	wire [1:0]	f21_rs7_opd_wr;
	wire		f21_rs7_opd_rdy;
	wire [63:0]	f21_rt7_opd_data;
	wire [1:0]	f21_rt7_opd_wr;
	wire		f21_rt7_opd_rdy;

	/** Operand FIFO interface **/
	wire [31:0]	op_rs0_data;
	reg		op_rs0_rd;
	wire		op_rs0_vld;
	wire [31:0]	op_rt0_data;
	reg		op_rt0_rd;
	wire		op_rt0_vld;
	wire [31:0]	op_rs1_data;
	reg		op_rs1_rd;
	wire		op_rs1_vld;
	wire [31:0]	op_rt1_data;
	reg		op_rt1_rd;
	wire		op_rt1_vld;
	wire [31:0]	op_rs2_data;
	reg		op_rs2_rd;
	wire		op_rs2_vld;
	wire [31:0]	op_rt2_data;
	reg		op_rt2_rd;
	wire		op_rt2_vld;
	wire [31:0]	op_rs3_data;
	reg		op_rs3_rd;
	wire		op_rs3_vld;
	wire [31:0]	op_rt3_data;
	reg		op_rt3_rd;
	wire		op_rt3_vld;
	wire [31:0]	op_rs4_data;
	reg		op_rs4_rd;
	wire		op_rs4_vld;
	wire [31:0]	op_rt4_data;
	reg		op_rt4_rd;
	wire		op_rt4_vld;
	wire [31:0]	op_rs5_data;
	reg		op_rs5_rd;
	wire		op_rs5_vld;
	wire [31:0]	op_rt5_data;
	reg		op_rt5_rd;
	wire		op_rt5_vld;
	wire [31:0]	op_rs6_data;
	reg		op_rs6_rd;
	wire		op_rs6_vld;
	wire [31:0]	op_rt6_data;
	reg		op_rt6_rd;
	wire		op_rt6_vld;
	wire [31:0]	op_rs7_data;
	reg		op_rs7_rd;
	wire		op_rs7_vld;
	wire [31:0]	op_rt7_data;
	reg		op_rt7_rd;
	wire		op_rt7_vld;

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


	/* Set response */
	task set_resp;
	input [2:0]	th;	/* Thread No. 0 - 7 */
	input		arg;	/* Argument Rs=0 / Rt=1 */
	input [63:0]	data;	/* Data */
	begin
		@(posedge clk)
		begin
			rrs_vld <= 1'b1;
			rrs_th <= th;
			rrs_arg <= arg;
			rrs_data <= data;
		end
		@(posedge clk) ;	/* 1 cycle delay */
		@(posedge clk)
			rrs_vld <= 1'b0;
	end
	endtask


	/* Set write enable */
	task set_we;
	input [2:0]	th;	/* Thread No. 0 - 7 */
	input		arg;	/* Argument Rs=0 / Rt=1 */
	input [1:0]	mask;	/* Write enable mask */
	begin
		@(posedge clk)
		begin
			case({th, arg})
			4'b0000: begin
				rrs_rs0_we_mask <= mask;
				rrs_rs0_we_vld <= 1'b1;
			end
			4'b0001: begin
				rrs_rt0_we_mask <= mask;
				rrs_rt0_we_vld <= 1'b1;
			end
			4'b0010: begin
				rrs_rs1_we_mask <= mask;
				rrs_rs1_we_vld <= 1'b1;
			end
			4'b0011: begin
				rrs_rt1_we_mask <= mask;
				rrs_rt1_we_vld <= 1'b1;
			end
			4'b0100: begin
				rrs_rs2_we_mask <= mask;
				rrs_rs2_we_vld <= 1'b1;
			end
			4'b0101: begin
				rrs_rt2_we_mask <= mask;
				rrs_rt2_we_vld <= 1'b1;
			end
			4'b0110: begin
				rrs_rs3_we_mask <= mask;
				rrs_rs3_we_vld <= 1'b1;
			end
			4'b0111: begin
				rrs_rt3_we_mask <= mask;
				rrs_rt3_we_vld <= 1'b1;
			end
			4'b1000: begin
				rrs_rs4_we_mask <= mask;
				rrs_rs4_we_vld <= 1'b1;
			end
			4'b1001: begin
				rrs_rt4_we_mask <= mask;
				rrs_rt4_we_vld <= 1'b1;
			end
			4'b1010: begin
				rrs_rs5_we_mask <= mask;
				rrs_rs5_we_vld <= 1'b1;
			end
			4'b1011: begin
				rrs_rt5_we_mask <= mask;
				rrs_rt5_we_vld <= 1'b1;
			end
			4'b1100: begin
				rrs_rs6_we_mask <= mask;
				rrs_rs6_we_vld <= 1'b1;
			end
			4'b1101: begin
				rrs_rt6_we_mask <= mask;
				rrs_rt6_we_vld <= 1'b1;
			end
			4'b1110: begin
				rrs_rs7_we_mask <= mask;
				rrs_rs7_we_vld <= 1'b1;
			end
			4'b1111: begin
				rrs_rt7_we_mask <= mask;
				rrs_rt7_we_vld <= 1'b1;
			end
			default: $display("set_we: wrong args!");
			endcase
		end
		@(posedge clk) ;	/* 1 cycle delay */
		@(posedge clk)
		begin
			rrs_rs0_we_vld <= 1'b0;
			rrs_rt0_we_vld <= 1'b0;
			rrs_rs1_we_vld <= 1'b0;
			rrs_rt1_we_vld <= 1'b0;
			rrs_rs2_we_vld <= 1'b0;
			rrs_rt2_we_vld <= 1'b0;
			rrs_rs3_we_vld <= 1'b0;
			rrs_rt3_we_vld <= 1'b0;
			rrs_rs4_we_vld <= 1'b0;
			rrs_rt4_we_vld <= 1'b0;
			rrs_rs5_we_vld <= 1'b0;
			rrs_rt5_we_vld <= 1'b0;
			rrs_rs6_we_vld <= 1'b0;
			rrs_rt6_we_vld <= 1'b0;
			rrs_rs7_we_vld <= 1'b0;
			rrs_rt7_we_vld <= 1'b0;
		end
	end
	endtask


	/* Set response and write enable */
	task set_resp_we;
	input [2:0]	th;	/* Thread No. 0 - 7 */
	input		arg;	/* Argument Rs=0 / Rt=1 */
	input [63:0]	data;	/* Data */
	input [1:0]	mask;	/* Write enable mask */
	begin
		@(posedge clk)
		begin
			rrs_vld <= 1'b1;
			rrs_th <= th;
			rrs_arg <= arg;
			rrs_data <= data;

			case({th, arg})
			4'b0000: begin
				rrs_rs0_we_mask <= mask;
				rrs_rs0_we_vld <= 1'b1;
			end
			4'b0001: begin
				rrs_rt0_we_mask <= mask;
				rrs_rt0_we_vld <= 1'b1;
			end
			4'b0010: begin
				rrs_rs1_we_mask <= mask;
				rrs_rs1_we_vld <= 1'b1;
			end
			4'b0011: begin
				rrs_rt1_we_mask <= mask;
				rrs_rt1_we_vld <= 1'b1;
			end
			4'b0100: begin
				rrs_rs2_we_mask <= mask;
				rrs_rs2_we_vld <= 1'b1;
			end
			4'b0101: begin
				rrs_rt2_we_mask <= mask;
				rrs_rt2_we_vld <= 1'b1;
			end
			4'b0110: begin
				rrs_rs3_we_mask <= mask;
				rrs_rs3_we_vld <= 1'b1;
			end
			4'b0111: begin
				rrs_rt3_we_mask <= mask;
				rrs_rt3_we_vld <= 1'b1;
			end
			4'b1000: begin
				rrs_rs4_we_mask <= mask;
				rrs_rs4_we_vld <= 1'b1;
			end
			4'b1001: begin
				rrs_rt4_we_mask <= mask;
				rrs_rt4_we_vld <= 1'b1;
			end
			4'b1010: begin
				rrs_rs5_we_mask <= mask;
				rrs_rs5_we_vld <= 1'b1;
			end
			4'b1011: begin
				rrs_rt5_we_mask <= mask;
				rrs_rt5_we_vld <= 1'b1;
			end
			4'b1100: begin
				rrs_rs6_we_mask <= mask;
				rrs_rs6_we_vld <= 1'b1;
			end
			4'b1101: begin
				rrs_rt6_we_mask <= mask;
				rrs_rt6_we_vld <= 1'b1;
			end
			4'b1110: begin
				rrs_rs7_we_mask <= mask;
				rrs_rs7_we_vld <= 1'b1;
			end
			4'b1111: begin
				rrs_rt7_we_mask <= mask;
				rrs_rt7_we_vld <= 1'b1;
			end
			default: $display("set_resp_we: wrong args!");
			endcase
		end
		@(posedge clk) ;	/* 1 cycle delay */
		@(posedge clk)
		begin
			rrs_vld <= 1'b0;
			rrs_rs0_we_vld <= 1'b0;
			rrs_rt0_we_vld <= 1'b0;
			rrs_rs1_we_vld <= 1'b0;
			rrs_rt1_we_vld <= 1'b0;
			rrs_rs2_we_vld <= 1'b0;
			rrs_rt2_we_vld <= 1'b0;
			rrs_rs3_we_vld <= 1'b0;
			rrs_rt3_we_vld <= 1'b0;
			rrs_rs4_we_vld <= 1'b0;
			rrs_rt4_we_vld <= 1'b0;
			rrs_rs5_we_vld <= 1'b0;
			rrs_rt5_we_vld <= 1'b0;
			rrs_rs6_we_vld <= 1'b0;
			rrs_rt6_we_vld <= 1'b0;
			rrs_rs7_we_vld <= 1'b0;
			rrs_rt7_we_vld <= 1'b0;
		end
	end
	endtask


	/* Set response and write enable */
	task set_op_read;
	input [15:0]	op_mask;
	begin
		@(posedge clk)
		begin
			op_rs0_rd <= op_mask[0];
			op_rt0_rd <= op_mask[1];
			op_rs1_rd <= op_mask[2];
			op_rt1_rd <= op_mask[3];
			op_rs2_rd <= op_mask[4];
			op_rt2_rd <= op_mask[5];
			op_rs3_rd <= op_mask[6];
			op_rt3_rd <= op_mask[7];
			op_rs4_rd <= op_mask[8];
			op_rt4_rd <= op_mask[9];
			op_rs5_rd <= op_mask[10];
			op_rt5_rd <= op_mask[11];
			op_rs6_rd <= op_mask[12];
			op_rt6_rd <= op_mask[13];
			op_rs7_rd <= op_mask[14];
			op_rt7_rd <= op_mask[15];
		end
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_prod_eu_rs_dist);

		clk = 1'b1;
		nrst = 1'b0;

		rrs_vld = 1'b0;

		rrs_rs0_we_vld = 1'b0;
		rrs_rt0_we_vld = 1'b0;
		rrs_rs1_we_vld = 1'b0;
		rrs_rt1_we_vld = 1'b0;
		rrs_rs2_we_vld = 1'b0;
		rrs_rt2_we_vld = 1'b0;
		rrs_rs3_we_vld = 1'b0;
		rrs_rt3_we_vld = 1'b0;
		rrs_rs4_we_vld = 1'b0;
		rrs_rt4_we_vld = 1'b0;
		rrs_rs5_we_vld = 1'b0;
		rrs_rt5_we_vld = 1'b0;
		rrs_rs6_we_vld = 1'b0;
		rrs_rt6_we_vld = 1'b0;
		rrs_rs7_we_vld = 1'b0;
		rrs_rt7_we_vld = 1'b0;

		op_rs0_rd = 1'b0;
		op_rt0_rd = 1'b0;
		op_rs1_rd = 1'b0;
		op_rt1_rd = 1'b0;
		op_rs2_rd = 1'b0;
		op_rt2_rd = 1'b0;
		op_rs3_rd = 1'b0;
		op_rt3_rd = 1'b0;
		op_rs4_rd = 1'b0;
		op_rt4_rd = 1'b0;
		op_rs5_rd = 1'b0;
		op_rt5_rd = 1'b0;
		op_rs6_rd = 1'b0;
		op_rt6_rd = 1'b0;
		op_rs7_rd = 1'b0;
		op_rt7_rd = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(1);
		/***********************************************************/


`ifdef TESTS_SINGLE_RESP
		/*** Test 00 - Response thread 0, arg Rs ****/
		test("Test_00", 0);
		set_resp_we(3'd0, 1'b0, 64'hd200_0000_d100_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_00", 4);

		/*** Test 01 - Response thread 0, arg Rt ****/
		test("Test_01", 0);
		set_resp_we(3'd0, 1'b1, 64'hd201_0000_d101_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_01", 4);


		/*** Test 02 - Response thread 1, arg Rs ****/
		test("Test_02", 0);
		set_resp_we(3'd1, 1'b0, 64'hd210_0000_d110_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_01_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_02", 4);

		/*** Test 03 - Response thread 1, arg Rt ****/
		test("Test_03", 0);
		set_resp_we(3'd1, 1'b1, 64'hd211_0000_d111_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_10_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_03", 4);


		/*** Test 04 - Response thread 2, arg Rs ****/
		test("Test_04", 0);
		set_resp_we(3'd2, 1'b0, 64'hd220_0000_d120_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_01_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_04", 4);

		/*** Test 05 - Response thread 2, arg Rt ****/
		test("Test_05", 0);
		set_resp_we(3'd2, 1'b1, 64'hd221_0000_d121_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_10_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_05", 4);


		/*** Test 06 - Response thread 3, arg Rs ****/
		test("Test_06", 0);
		set_resp_we(3'd3, 1'b0, 64'hd230_0000_d130_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_01_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_06", 4);

		/*** Test 07 - Response thread 3, arg Rt ****/
		test("Test_07", 0);
		set_resp_we(3'd3, 1'b1, 64'hd231_0000_d131_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_10_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_07", 4);


		/*** Test 08 - Response thread 4, arg Rs ****/
		test("Test_08", 0);
		set_resp_we(3'd4, 1'b0, 64'hd240_0000_d140_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_01_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_08", 4);

		/*** Test 09 - Response thread 4, arg Rt ****/
		test("Test_09", 0);
		set_resp_we(3'd4, 1'b1, 64'hd241_0000_d141_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_10_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_09", 4);


		/*** Test 10 - Response thread 5, arg Rs ****/
		test("Test_10", 0);
		set_resp_we(3'd5, 1'b0, 64'hd250_0000_d150_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_01_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_10", 4);

		/*** Test 11 - Response thread 5, arg Rt ****/
		test("Test_11", 0);
		set_resp_we(3'd5, 1'b1, 64'hd251_0000_d151_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_00_10_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_11", 4);


		/*** Test 12 - Response thread 6, arg Rs ****/
		test("Test_12", 0);
		set_resp_we(3'd6, 1'b0, 64'hd260_0000_d160_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_01_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_12", 4);

		/*** Test 13 - Response thread 6, arg Rt ****/
		test("Test_13", 0);
		set_resp_we(3'd6, 1'b1, 64'hd261_0000_d161_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b00_10_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_13", 4);


		/*** Test 14 - Response thread 7, arg Rs ****/
		test("Test_14", 0);
		set_resp_we(3'd7, 1'b0, 64'hd270_0000_d170_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b01_00_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_14", 4);

		/*** Test 15 - Response thread 7, arg Rt ****/
		test("Test_15", 0);
		set_resp_we(3'd7, 1'b1, 64'hd271_0000_d171_0000, 2'b11);
		wait_pos_clk(4);
		set_op_read(16'b10_00_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_15", 4);
`endif


`ifdef TESTS_CLOGGED_PATH
		/*** Test 16 - Receive path clogged (Thread 0, arg Rs) ****/
		test("Test_16", 0);
		set_resp_we(3'd0, 1'b0, 64'hd200_0001_d100_0000, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0003_d100_0002, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0005_d100_0004, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0007_d100_0006, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0009_d100_0008, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0011_d100_0010, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0013_d100_0012, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0015_d100_0014, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0017_d100_0016, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0019_d100_0018, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0021_d100_0020, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0023_d100_0022, 2'b11);
		set_resp_we(3'd0, 1'b0, 64'hd200_0025_d100_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_00_00_00_01);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_16", 4);

		/*** Test 17 - Receive path clogged (Thread 0, arg Rt) ****/
		test("Test_17", 0);
		set_resp_we(3'd0, 1'b1, 64'hd201_0001_d101_0000, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0003_d101_0002, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0005_d101_0004, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0007_d101_0006, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0009_d101_0008, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0011_d101_0010, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0013_d101_0012, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0015_d101_0014, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0017_d101_0016, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0019_d101_0018, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0021_d101_0020, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0023_d101_0022, 2'b11);
		set_resp_we(3'd0, 1'b1, 64'hd201_0025_d101_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_00_00_00_10);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_17", 4);


		/*** Test 18 - Receive path clogged (Thread 1, arg Rs) ****/
		test("Test_18", 0);
		set_resp_we(3'd1, 1'b0, 64'hd210_0001_d110_0000, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0003_d110_0002, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0005_d110_0004, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0007_d110_0006, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0009_d110_0008, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0011_d110_0010, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0013_d110_0012, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0015_d110_0014, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0017_d110_0016, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0019_d110_0018, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0021_d110_0020, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0023_d110_0022, 2'b11);
		set_resp_we(3'd1, 1'b0, 64'hd210_0025_d110_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_00_00_01_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_18", 4);

		/*** Test 19 - Receive path clogged (Thread 1, arg Rt) ****/
		test("Test_19", 0);
		set_resp_we(3'd1, 1'b1, 64'hd211_0001_d111_0000, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0003_d111_0002, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0005_d111_0004, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0007_d111_0006, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0009_d111_0008, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0011_d111_0010, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0013_d111_0012, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0015_d111_0014, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0017_d111_0016, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0019_d111_0018, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0021_d111_0020, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0023_d111_0022, 2'b11);
		set_resp_we(3'd1, 1'b1, 64'hd211_0025_d111_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_00_00_10_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_19", 4);


		/*** Test 20 - Receive path clogged (Thread 2, arg Rs) ****/
		test("Test_20", 0);
		set_resp_we(3'd2, 1'b0, 64'hd220_0001_d120_0000, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0003_d120_0002, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0005_d120_0004, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0007_d120_0006, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0009_d120_0008, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0011_d120_0010, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0013_d120_0012, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0015_d120_0014, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0017_d120_0016, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0019_d120_0018, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0021_d120_0020, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0023_d120_0022, 2'b11);
		set_resp_we(3'd2, 1'b0, 64'hd220_0025_d120_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_00_01_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_20", 4);

		/*** Test 21 - Receive path clogged (Thread 2, arg Rt) ****/
		test("Test_21", 0);
		set_resp_we(3'd2, 1'b1, 64'hd221_0001_d121_0000, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0003_d121_0002, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0005_d121_0004, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0007_d121_0006, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0009_d121_0008, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0011_d121_0010, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0013_d121_0012, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0015_d121_0014, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0017_d121_0016, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0019_d121_0018, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0021_d121_0020, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0023_d121_0022, 2'b11);
		set_resp_we(3'd2, 1'b1, 64'hd221_0025_d121_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_00_10_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_21", 4);


		/*** Test 22 - Receive path clogged (Thread 3, arg Rs) ****/
		test("Test_22", 0);
		set_resp_we(3'd3, 1'b0, 64'hd230_0001_d130_0000, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0003_d130_0002, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0005_d130_0004, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0007_d130_0006, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0009_d130_0008, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0011_d130_0010, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0013_d130_0012, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0015_d130_0014, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0017_d130_0016, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0019_d130_0018, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0021_d130_0020, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0023_d130_0022, 2'b11);
		set_resp_we(3'd3, 1'b0, 64'hd230_0025_d130_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_01_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_22", 4);

		/*** Test 23 - Receive path clogged (Thread 3, arg Rt) ****/
		test("Test_23", 0);
		set_resp_we(3'd3, 1'b1, 64'hd231_0001_d131_0000, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0003_d131_0002, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0005_d131_0004, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0007_d131_0006, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0009_d131_0008, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0011_d131_0010, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0013_d131_0012, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0015_d131_0014, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0017_d131_0016, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0019_d131_0018, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0021_d131_0020, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0023_d131_0022, 2'b11);
		set_resp_we(3'd3, 1'b1, 64'hd231_0025_d131_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_00_10_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_23", 4);


		/*** Test 24 - Receive path clogged (Thread 4, arg Rs) ****/
		test("Test_24", 0);
		set_resp_we(3'd4, 1'b0, 64'hd240_0001_d140_0000, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0003_d140_0002, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0005_d140_0004, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0007_d140_0006, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0009_d140_0008, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0011_d140_0010, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0013_d140_0012, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0015_d140_0014, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0017_d140_0016, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0019_d140_0018, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0021_d140_0020, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0023_d140_0022, 2'b11);
		set_resp_we(3'd4, 1'b0, 64'hd240_0025_d140_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_01_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_24", 4);

		/*** Test 25 - Receive path clogged (Thread 4, arg Rt) ****/
		test("Test_25", 0);
		set_resp_we(3'd4, 1'b1, 64'hd241_0001_d141_0000, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0003_d141_0002, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0005_d141_0004, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0007_d141_0006, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0009_d141_0008, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0011_d141_0010, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0013_d141_0012, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0015_d141_0014, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0017_d141_0016, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0019_d141_0018, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0021_d141_0020, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0023_d141_0022, 2'b11);
		set_resp_we(3'd4, 1'b1, 64'hd241_0025_d141_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_00_10_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_25", 4);


		/*** Test 26 - Receive path clogged (Thread 5, arg Rs) ****/
		test("Test_26", 0);
		set_resp_we(3'd5, 1'b0, 64'hd250_0001_d150_0000, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0003_d150_0002, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0005_d150_0004, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0007_d150_0006, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0009_d150_0008, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0011_d150_0010, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0013_d150_0012, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0015_d150_0014, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0017_d150_0016, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0019_d150_0018, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0021_d150_0020, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0023_d150_0022, 2'b11);
		set_resp_we(3'd5, 1'b0, 64'hd250_0025_d150_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_01_00_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_26", 4);

		/*** Test 27 - Receive path clogged (Thread 5, arg Rt) ****/
		test("Test_27", 0);
		set_resp_we(3'd5, 1'b1, 64'hd251_0001_d151_0000, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0003_d151_0002, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0005_d151_0004, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0007_d151_0006, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0009_d151_0008, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0011_d151_0010, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0013_d151_0012, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0015_d151_0014, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0017_d151_0016, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0019_d151_0018, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0021_d151_0020, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0023_d151_0022, 2'b11);
		set_resp_we(3'd5, 1'b1, 64'hd251_0025_d151_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_00_10_00_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_27", 4);


		/*** Test 28 - Receive path clogged (Thread 6, arg Rs) ****/
		test("Test_28", 0);
		set_resp_we(3'd6, 1'b0, 64'hd260_0001_d160_0000, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0003_d160_0002, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0005_d160_0004, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0007_d160_0006, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0009_d160_0008, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0011_d160_0010, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0013_d160_0012, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0015_d160_0014, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0017_d160_0016, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0019_d160_0018, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0021_d160_0020, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0023_d160_0022, 2'b11);
		set_resp_we(3'd6, 1'b0, 64'hd260_0025_d160_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_01_00_00_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_28", 4);

		/*** Test 29 - Receive path clogged (Thread 6, arg Rt) ****/
		test("Test_29", 0);
		set_resp_we(3'd6, 1'b1, 64'hd261_0001_d161_0000, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0003_d161_0002, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0005_d161_0004, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0007_d161_0006, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0009_d161_0008, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0011_d161_0010, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0013_d161_0012, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0015_d161_0014, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0017_d161_0016, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0019_d161_0018, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0021_d161_0020, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0023_d161_0022, 2'b11);
		set_resp_we(3'd6, 1'b1, 64'hd261_0025_d161_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b00_10_00_00_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_29", 4);


		/*** Test 30 - Receive path clogged (Thread 7, arg Rs) ****/
		test("Test_30", 0);
		set_resp_we(3'd7, 1'b0, 64'hd270_0001_d170_0000, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0003_d170_0002, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0005_d170_0004, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0007_d170_0006, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0009_d170_0008, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0011_d170_0010, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0013_d170_0012, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0015_d170_0014, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0017_d170_0016, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0019_d170_0018, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0021_d170_0020, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0023_d170_0022, 2'b11);
		set_resp_we(3'd7, 1'b0, 64'hd270_0025_d170_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b01_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_30", 4);

		/*** Test 31 - Receive path clogged (Thread 7, arg Rt) ****/
		test("Test_31", 0);
		set_resp_we(3'd7, 1'b1, 64'hd271_0001_d171_0000, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0003_d171_0002, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0005_d171_0004, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0007_d171_0006, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0009_d171_0008, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0011_d171_0010, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0013_d171_0012, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0015_d171_0014, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0017_d171_0016, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0019_d171_0018, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0021_d171_0020, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0023_d171_0022, 2'b11);
		set_resp_we(3'd7, 1'b1, 64'hd271_0025_d171_0024, 2'b11); /* This should be dropped */
		wait_pos_clk(8);
		set_op_read(16'b10_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_31", 4);
`endif


`ifdef TESTS_LOWORD_RESP
		/*** Test 32 - Response thread 0, arg Rs ****/
		test("Test_32", 0);
		set_resp_we(3'd0, 1'b0, 64'hd200_0000_d100_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_32", 4);

		/*** Test 33 - Response thread 0, arg Rt ****/
		test("Test_33", 0);
		set_resp_we(3'd0, 1'b1, 64'hd201_0000_d101_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_33", 4);


		/*** Test 34 - Response thread 1, arg Rs ****/
		test("Test_34", 0);
		set_resp_we(3'd1, 1'b0, 64'hd210_0000_d110_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_01_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_34", 4);

		/*** Test 35 - Response thread 1, arg Rt ****/
		test("Test_35", 0);
		set_resp_we(3'd1, 1'b1, 64'hd211_0000_d111_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_10_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_35", 4);


		/*** Test 36 - Response thread 2, arg Rs ****/
		test("Test_36", 0);
		set_resp_we(3'd2, 1'b0, 64'hd220_0000_d120_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_01_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_36", 4);

		/*** Test 37 - Response thread 2, arg Rt ****/
		test("Test_37", 0);
		set_resp_we(3'd2, 1'b1, 64'hd221_0000_d121_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_10_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_37", 4);


		/*** Test 38 - Response thread 3, arg Rs ****/
		test("Test_38", 0);
		set_resp_we(3'd3, 1'b0, 64'hd230_0000_d130_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_01_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_38", 4);

		/*** Test 39 - Response thread 3, arg Rt ****/
		test("Test_39", 0);
		set_resp_we(3'd3, 1'b1, 64'hd231_0000_d131_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_10_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_39", 4);


		/*** Test 40 - Response thread 4, arg Rs ****/
		test("Test_40", 0);
		set_resp_we(3'd4, 1'b0, 64'hd240_0000_d140_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_01_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_40", 4);

		/*** Test 41 - Response thread 4, arg Rt ****/
		test("Test_41", 0);
		set_resp_we(3'd4, 1'b1, 64'hd241_0000_d141_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_10_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_41", 4);


		/*** Test 42 - Response thread 5, arg Rs ****/
		test("Test_42", 0);
		set_resp_we(3'd5, 1'b0, 64'hd250_0000_d150_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_01_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_42", 4);

		/*** Test 43 - Response thread 5, arg Rt ****/
		test("Test_43", 0);
		set_resp_we(3'd5, 1'b1, 64'hd251_0000_d151_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_10_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_43", 4);


		/*** Test 44 - Response thread 6, arg Rs ****/
		test("Test_44", 0);
		set_resp_we(3'd6, 1'b0, 64'hd260_0000_d160_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_01_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_44", 4);

		/*** Test 45 - Response thread 6, arg Rt ****/
		test("Test_45", 0);
		set_resp_we(3'd6, 1'b1, 64'hd261_0000_d161_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b00_10_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_45", 4);


		/*** Test 46 - Response thread 7, arg Rs ****/
		test("Test_46", 0);
		set_resp_we(3'd7, 1'b0, 64'hd270_0000_d170_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b01_00_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_46", 4);

		/*** Test 47 - Response thread 7, arg Rt ****/
		test("Test_47", 0);
		set_resp_we(3'd7, 1'b1, 64'hd271_0000_d171_0000, 2'b01);
		wait_pos_clk(4);
		set_op_read(16'b10_00_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_47", 4);
`endif


`ifdef TESTS_HIWORD_RESP
		/*** Test 48 - Response thread 0, arg Rs ****/
		test("Test_48", 0);
		set_resp_we(3'd0, 1'b0, 64'hd200_0000_d100_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_01);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_48", 4);

		/*** Test 49 - Response thread 0, arg Rt ****/
		test("Test_49", 0);
		set_resp_we(3'd0, 1'b1, 64'hd201_0000_d101_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_49", 4);


		/*** Test 50 - Response thread 1, arg Rs ****/
		test("Test_50", 0);
		set_resp_we(3'd1, 1'b0, 64'hd210_0000_d110_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_01_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_50", 4);

		/*** Test 51 - Response thread 1, arg Rt ****/
		test("Test_51", 0);
		set_resp_we(3'd1, 1'b1, 64'hd211_0000_d111_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_10_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_51", 4);


		/*** Test 52 - Response thread 2, arg Rs ****/
		test("Test_52", 0);
		set_resp_we(3'd2, 1'b0, 64'hd220_0000_d120_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_01_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_52", 4);

		/*** Test 53 - Response thread 2, arg Rt ****/
		test("Test_53", 0);
		set_resp_we(3'd2, 1'b1, 64'hd221_0000_d121_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_10_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_53", 4);


		/*** Test 54 - Response thread 3, arg Rs ****/
		test("Test_54", 0);
		set_resp_we(3'd3, 1'b0, 64'hd230_0000_d130_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_01_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_54", 4);

		/*** Test 55 - Response thread 3, arg Rt ****/
		test("Test_55", 0);
		set_resp_we(3'd3, 1'b1, 64'hd231_0000_d131_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_10_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_55", 4);


		/*** Test 56 - Response thread 4, arg Rs ****/
		test("Test_56", 0);
		set_resp_we(3'd4, 1'b0, 64'hd240_0000_d140_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_01_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_56", 4);

		/*** Test 57 - Response thread 4, arg Rt ****/
		test("Test_57", 0);
		set_resp_we(3'd4, 1'b1, 64'hd241_0000_d141_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_10_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_57", 4);


		/*** Test 58 - Response thread 5, arg Rs ****/
		test("Test_58", 0);
		set_resp_we(3'd5, 1'b0, 64'hd250_0000_d150_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_01_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_58", 4);

		/*** Test 59 - Response thread 5, arg Rt ****/
		test("Test_59", 0);
		set_resp_we(3'd5, 1'b1, 64'hd251_0000_d151_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_00_10_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_59", 4);


		/*** Test 60 - Response thread 6, arg Rs ****/
		test("Test_60", 0);
		set_resp_we(3'd6, 1'b0, 64'hd260_0000_d160_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_01_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_60", 4);

		/*** Test 61 - Response thread 6, arg Rt ****/
		test("Test_61", 0);
		set_resp_we(3'd6, 1'b1, 64'hd261_0000_d161_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b00_10_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_61", 4);


		/*** Test 62 - Response thread 7, arg Rs ****/
		test("Test_62", 0);
		set_resp_we(3'd7, 1'b0, 64'hd270_0000_d170_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b01_00_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_62", 4);

		/*** Test 63 - Response thread 7, arg Rt ****/
		test("Test_63", 0);
		set_resp_we(3'd7, 1'b1, 64'hd271_0000_d171_0000, 2'b10);
		wait_pos_clk(4);
		set_op_read(16'b10_00_00_00_00_00_00_00);
		wait_pos_clk(4);
		set_op_read(16'b00_00_00_00_00_00_00_00);
		test("Done_63", 4);
`endif


		#500 $finish;
	end



	/* Responses distributor unit */
	vxe_vpu_prod_eu_rs_dist #(
		.IN_WE_DEPTH_POW2(2),
		.IN_RS_DEPTH_POW2(2),
		.OUT_OP_DEPTH_POW2(2)
	) rs_dist (
		.clk(clk),
		.nrst(nrst),
		.o_busy(busy),
		.i_rrs_vld(rrs_vld),
		.o_rrs_rd(rrs_rd),
		.i_rrs_th(rrs_th),
		.i_rrs_arg(rrs_arg),
		.i_rrs_data(rrs_data),
		.i_rrs_rs0_we_mask(rrs_rs0_we_mask),
		.o_rrs_rs0_we_rd(rrs_rs0_we_rd),
		.i_rrs_rs0_we_vld(rrs_rs0_we_vld),
		.i_rrs_rt0_we_mask(rrs_rt0_we_mask),
		.o_rrs_rt0_we_rd(rrs_rt0_we_rd),
		.i_rrs_rt0_we_vld(rrs_rt0_we_vld),
		.i_rrs_rs1_we_mask(rrs_rs1_we_mask),
		.o_rrs_rs1_we_rd(rrs_rs1_we_rd),
		.i_rrs_rs1_we_vld(rrs_rs1_we_vld),
		.i_rrs_rt1_we_mask(rrs_rt1_we_mask),
		.o_rrs_rt1_we_rd(rrs_rt1_we_rd),
		.i_rrs_rt1_we_vld(rrs_rt1_we_vld),
		.i_rrs_rs2_we_mask(rrs_rs2_we_mask),
		.o_rrs_rs2_we_rd(rrs_rs2_we_rd),
		.i_rrs_rs2_we_vld(rrs_rs2_we_vld),
		.i_rrs_rt2_we_mask(rrs_rt2_we_mask),
		.o_rrs_rt2_we_rd(rrs_rt2_we_rd),
		.i_rrs_rt2_we_vld(rrs_rt2_we_vld),
		.i_rrs_rs3_we_mask(rrs_rs3_we_mask),
		.o_rrs_rs3_we_rd(rrs_rs3_we_rd),
		.i_rrs_rs3_we_vld(rrs_rs3_we_vld),
		.i_rrs_rt3_we_mask(rrs_rt3_we_mask),
		.o_rrs_rt3_we_rd(rrs_rt3_we_rd),
		.i_rrs_rt3_we_vld(rrs_rt3_we_vld),
		.i_rrs_rs4_we_mask(rrs_rs4_we_mask),
		.o_rrs_rs4_we_rd(rrs_rs4_we_rd),
		.i_rrs_rs4_we_vld(rrs_rs4_we_vld),
		.i_rrs_rt4_we_mask(rrs_rt4_we_mask),
		.o_rrs_rt4_we_rd(rrs_rt4_we_rd),
		.i_rrs_rt4_we_vld(rrs_rt4_we_vld),
		.i_rrs_rs5_we_mask(rrs_rs5_we_mask),
		.o_rrs_rs5_we_rd(rrs_rs5_we_rd),
		.i_rrs_rs5_we_vld(rrs_rs5_we_vld),
		.i_rrs_rt5_we_mask(rrs_rt5_we_mask),
		.o_rrs_rt5_we_rd(rrs_rt5_we_rd),
		.i_rrs_rt5_we_vld(rrs_rt5_we_vld),
		.i_rrs_rs6_we_mask(rrs_rs6_we_mask),
		.o_rrs_rs6_we_rd(rrs_rs6_we_rd),
		.i_rrs_rs6_we_vld(rrs_rs6_we_vld),
		.i_rrs_rt6_we_mask(rrs_rt6_we_mask),
		.o_rrs_rt6_we_rd(rrs_rt6_we_rd),
		.i_rrs_rt6_we_vld(rrs_rt6_we_vld),
		.i_rrs_rs7_we_mask(rrs_rs7_we_mask),
		.o_rrs_rs7_we_rd(rrs_rs7_we_rd),
		.i_rrs_rs7_we_vld(rrs_rs7_we_vld),
		.i_rrs_rt7_we_mask(rrs_rt7_we_mask),
		.o_rrs_rt7_we_rd(rrs_rt7_we_rd),
		.i_rrs_rt7_we_vld(rrs_rt7_we_vld),
		.o_f21_rs0_opd_data(f21_rs0_opd_data),
		.o_f21_rs0_opd_wr(f21_rs0_opd_wr),
		.i_f21_rs0_opd_rdy(f21_rs0_opd_rdy),
		.o_f21_rt0_opd_data(f21_rt0_opd_data),
		.o_f21_rt0_opd_wr(f21_rt0_opd_wr),
		.i_f21_rt0_opd_rdy(f21_rt0_opd_rdy),
		.o_f21_rs1_opd_data(f21_rs1_opd_data),
		.o_f21_rs1_opd_wr(f21_rs1_opd_wr),
		.i_f21_rs1_opd_rdy(f21_rs1_opd_rdy),
		.o_f21_rt1_opd_data(f21_rt1_opd_data),
		.o_f21_rt1_opd_wr(f21_rt1_opd_wr),
		.i_f21_rt1_opd_rdy(f21_rt1_opd_rdy),
		.o_f21_rs2_opd_data(f21_rs2_opd_data),
		.o_f21_rs2_opd_wr(f21_rs2_opd_wr),
		.i_f21_rs2_opd_rdy(f21_rs2_opd_rdy),
		.o_f21_rt2_opd_data(f21_rt2_opd_data),
		.o_f21_rt2_opd_wr(f21_rt2_opd_wr),
		.i_f21_rt2_opd_rdy(f21_rt2_opd_rdy),
		.o_f21_rs3_opd_data(f21_rs3_opd_data),
		.o_f21_rs3_opd_wr(f21_rs3_opd_wr),
		.i_f21_rs3_opd_rdy(f21_rs3_opd_rdy),
		.o_f21_rt3_opd_data(f21_rt3_opd_data),
		.o_f21_rt3_opd_wr(f21_rt3_opd_wr),
		.i_f21_rt3_opd_rdy(f21_rt3_opd_rdy),
		.o_f21_rs4_opd_data(f21_rs4_opd_data),
		.o_f21_rs4_opd_wr(f21_rs4_opd_wr),
		.i_f21_rs4_opd_rdy(f21_rs4_opd_rdy),
		.o_f21_rt4_opd_data(f21_rt4_opd_data),
		.o_f21_rt4_opd_wr(f21_rt4_opd_wr),
		.i_f21_rt4_opd_rdy(f21_rt4_opd_rdy),
		.o_f21_rs5_opd_data(f21_rs5_opd_data),
		.o_f21_rs5_opd_wr(f21_rs5_opd_wr),
		.i_f21_rs5_opd_rdy(f21_rs5_opd_rdy),
		.o_f21_rt5_opd_data(f21_rt5_opd_data),
		.o_f21_rt5_opd_wr(f21_rt5_opd_wr),
		.i_f21_rt5_opd_rdy(f21_rt5_opd_rdy),
		.o_f21_rs6_opd_data(f21_rs6_opd_data),
		.o_f21_rs6_opd_wr(f21_rs6_opd_wr),
		.i_f21_rs6_opd_rdy(f21_rs6_opd_rdy),
		.o_f21_rt6_opd_data(f21_rt6_opd_data),
		.o_f21_rt6_opd_wr(f21_rt6_opd_wr),
		.i_f21_rt6_opd_rdy(f21_rt6_opd_rdy),
		.o_f21_rs7_opd_data(f21_rs7_opd_data),
		.o_f21_rs7_opd_wr(f21_rs7_opd_wr),
		.i_f21_rs7_opd_rdy(f21_rs7_opd_rdy),
		.o_f21_rt7_opd_data(f21_rt7_opd_data),
		.o_f21_rt7_opd_wr(f21_rt7_opd_wr),
		.i_f21_rt7_opd_rdy(f21_rt7_opd_rdy)
	);



	/* Operand 2x1 FIFOs */
	generate
		for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
		begin : f_t
			for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
			begin : r
				/* Block inputs/outputs */
				wire [63:0]	dat_in;
				wire [31:0]	dat_out;
				wire		rd;
				wire [1:0]	wr;
				wire		rdy;
				wire		vld;

				vxe_fifo2wxw #(
					.DATA_WIDTH(32),
					.DEPTH_POW2(2)
				) f (
					.clk(clk),
					.nrst(nrst),
					.data_in(dat_in),
					.data_out(dat_out),
					.rd(rd),
					.wr(wr),
					.in_rdy(rdy),
					.out_vld(vld)
				);

			end	/* for(j, ...) */
		end	/* for(i, ...) */
	endgenerate

	/** Setup FIFO connections **/

	/* Thread 0, Rs */
	assign f_t[0].r[0].dat_in = f21_rs0_opd_data;
	assign f_t[0].r[0].wr = f21_rs0_opd_wr;
	assign f21_rs0_opd_rdy = f_t[0].r[0].rdy;
	assign op_rs0_data = f_t[0].r[0].dat_out;
	assign f_t[0].r[0].rd = op_rs0_rd;
	assign op_rs0_vld = f_t[0].r[0].vld;
	/* Thread 0, Rt */
	assign f_t[0].r[1].dat_in = f21_rt0_opd_data;
	assign f_t[0].r[1].wr = f21_rt0_opd_wr;
	assign f21_rt0_opd_rdy = f_t[0].r[1].rdy;
	assign op_rt0_data = f_t[0].r[1].dat_out;
	assign f_t[0].r[1].rd = op_rt0_rd;
	assign op_rt0_vld = f_t[0].r[1].vld;
	/* Thread 1, Rs */
	assign f_t[1].r[0].dat_in = f21_rs1_opd_data;
	assign f_t[1].r[0].wr = f21_rs1_opd_wr;
	assign f21_rs1_opd_rdy = f_t[1].r[0].rdy;
	assign op_rs1_data = f_t[1].r[0].dat_out;
	assign f_t[1].r[0].rd = op_rs1_rd;
	assign op_rs1_vld = f_t[1].r[0].vld;
	/* Thread 1, Rt */
	assign f_t[1].r[1].dat_in = f21_rt1_opd_data;
	assign f_t[1].r[1].wr = f21_rt1_opd_wr;
	assign f21_rt1_opd_rdy = f_t[1].r[1].rdy;
	assign op_rt1_data = f_t[1].r[1].dat_out;
	assign f_t[1].r[1].rd = op_rt1_rd;
	assign op_rt1_vld = f_t[1].r[1].vld;
	/* Thread 2, Rs */
	assign f_t[2].r[0].dat_in = f21_rs2_opd_data;
	assign f_t[2].r[0].wr = f21_rs2_opd_wr;
	assign f21_rs2_opd_rdy = f_t[2].r[0].rdy;
	assign op_rs2_data = f_t[2].r[0].dat_out;
	assign f_t[2].r[0].rd = op_rs2_rd;
	assign op_rs2_vld = f_t[2].r[0].vld;
	/* Thread 2, Rt */
	assign f_t[2].r[1].dat_in = f21_rt2_opd_data;
	assign f_t[2].r[1].wr = f21_rt2_opd_wr;
	assign f21_rt2_opd_rdy = f_t[2].r[1].rdy;
	assign op_rt2_data = f_t[2].r[1].dat_out;
	assign f_t[2].r[1].rd = op_rt2_rd;
	assign op_rt2_vld = f_t[2].r[1].vld;
	/* Thread 3, Rs */
	assign f_t[3].r[0].dat_in = f21_rs3_opd_data;
	assign f_t[3].r[0].wr = f21_rs3_opd_wr;
	assign f21_rs3_opd_rdy = f_t[3].r[0].rdy;
	assign op_rs3_data = f_t[3].r[0].dat_out;
	assign f_t[3].r[0].rd = op_rs3_rd;
	assign op_rs3_vld = f_t[3].r[0].vld;
	/* Thread 3, Rt */
	assign f_t[3].r[1].dat_in = f21_rt3_opd_data;
	assign f_t[3].r[1].wr = f21_rt3_opd_wr;
	assign f21_rt3_opd_rdy = f_t[3].r[1].rdy;
	assign op_rt3_data = f_t[3].r[1].dat_out;
	assign f_t[3].r[1].rd = op_rt3_rd;
	assign op_rt3_vld = f_t[3].r[1].vld;
	/* Thread 4, Rs */
	assign f_t[4].r[0].dat_in = f21_rs4_opd_data;
	assign f_t[4].r[0].wr = f21_rs4_opd_wr;
	assign f21_rs4_opd_rdy = f_t[4].r[0].rdy;
	assign op_rs4_data = f_t[4].r[0].dat_out;
	assign f_t[4].r[0].rd = op_rs4_rd;
	assign op_rs4_vld = f_t[4].r[0].vld;
	/* Thread 4, Rt */
	assign f_t[4].r[1].dat_in = f21_rt4_opd_data;
	assign f_t[4].r[1].wr = f21_rt4_opd_wr;
	assign f21_rt4_opd_rdy = f_t[4].r[1].rdy;
	assign op_rt4_data = f_t[4].r[1].dat_out;
	assign f_t[4].r[1].rd = op_rt4_rd;
	assign op_rt4_vld = f_t[4].r[1].vld;
	/* Thread 5, Rs */
	assign f_t[5].r[0].dat_in = f21_rs5_opd_data;
	assign f_t[5].r[0].wr = f21_rs5_opd_wr;
	assign f21_rs5_opd_rdy = f_t[5].r[0].rdy;
	assign op_rs5_data = f_t[5].r[0].dat_out;
	assign f_t[5].r[0].rd = op_rs5_rd;
	assign op_rs5_vld = f_t[5].r[0].vld;
	/* Thread 5, Rt */
	assign f_t[5].r[1].dat_in = f21_rt5_opd_data;
	assign f_t[5].r[1].wr = f21_rt5_opd_wr;
	assign f21_rt5_opd_rdy = f_t[5].r[1].rdy;
	assign op_rt5_data = f_t[5].r[1].dat_out;
	assign f_t[5].r[1].rd = op_rt5_rd;
	assign op_rt5_vld = f_t[5].r[1].vld;
	/* Thread 6, Rs */
	assign f_t[6].r[0].dat_in = f21_rs6_opd_data;
	assign f_t[6].r[0].wr = f21_rs6_opd_wr;
	assign f21_rs6_opd_rdy = f_t[6].r[0].rdy;
	assign op_rs6_data = f_t[6].r[0].dat_out;
	assign f_t[6].r[0].rd = op_rs6_rd;
	assign op_rs6_vld = f_t[6].r[0].vld;
	/* Thread 6, Rt */
	assign f_t[6].r[1].dat_in = f21_rt6_opd_data;
	assign f_t[6].r[1].wr = f21_rt6_opd_wr;
	assign f21_rt6_opd_rdy = f_t[6].r[1].rdy;
	assign op_rt6_data = f_t[6].r[1].dat_out;
	assign f_t[6].r[1].rd = op_rt6_rd;
	assign op_rt6_vld = f_t[6].r[1].vld;
	/* Thread 7, Rs */
	assign f_t[7].r[0].dat_in = f21_rs7_opd_data;
	assign f_t[7].r[0].wr = f21_rs7_opd_wr;
	assign f21_rs7_opd_rdy = f_t[7].r[0].rdy;
	assign op_rs7_data = f_t[7].r[0].dat_out;
	assign f_t[7].r[0].rd = op_rs7_rd;
	assign op_rs7_vld = f_t[7].r[0].vld;
	/* Thread 7, Rt */
	assign f_t[7].r[1].dat_in = f21_rt7_opd_data;
	assign f_t[7].r[1].wr = f21_rt7_opd_wr;
	assign f21_rt7_opd_rdy = f_t[7].r[1].rdy;
	assign op_rt7_data = f_t[7].r[1].dat_out;
	assign f_t[7].r[1].rd = op_rt7_rd;
	assign op_rt7_vld = f_t[7].r[1].vld;


endmodule /* tb_vxe_vpu_prod_eu_rs_dist */
