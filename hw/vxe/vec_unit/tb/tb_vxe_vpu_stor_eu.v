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
 * Testbench for VxE VPU store execution unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


`define TESTS_SINGLE		/* Single thread */
`define TESTS_SINGLE_NA		/* Single thread with not aligned Rd */
`define TESTS_WC_GROUPS		/* Write combine groups */
`define TESTS_WC_GROUPS_SWAP	/* Swapped write combine groups */
`define TESTS_ALL_NO_WC		/* All threads active, no write combine */
`define TESTS_ALL_WC		/* All threads active, write combine */
`define TESTS_ALL_WC_SWAP	/* All threads active, swapped write combine */
`define TESTS_DST_BUSY_NO_WC	/* Destination busy, no write combine */
`define TESTS_DST_BUSY_WC	/* Destination busy, write combine */
`define TESTS_ALL_BUT_ONE	/* All threads active except one */



module tb_vxe_vpu_stor_eu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Control unit interface */
	reg		start;
	wire		busy;
	/* LSU interface */
	reg		lsu_wrq_rdy;
	wire		lsu_wrq_wr;
	wire [2:0]	lsu_wrq_th;
	wire [36:0]	lsu_wrq_addr;
	wire [1:0]	lsu_wrq_wen;
	wire [63:0]	lsu_wrq_data;
	/* Register values */
	reg [31:0]	th0_acc;
	reg		th0_en;
	reg [37:0]	th0_rd;
	reg [31:0]	th1_acc;
	reg		th1_en;
	reg [37:0]	th1_rd;
	reg [31:0]	th2_acc;
	reg		th2_en;
	reg [37:0]	th2_rd;
	reg [31:0]	th3_acc;
	reg		th3_en;
	reg [37:0]	th3_rd;
	reg [31:0]	th4_acc;
	reg		th4_en;
	reg [37:0]	th4_rd;
	reg [31:0]	th5_acc;
	reg		th5_en;
	reg [37:0]	th5_rd;
	reg [31:0]	th6_acc;
	reg		th6_en;
	reg [37:0]	th6_rd;
	reg [31:0]	th7_acc;
	reg		th7_en;
	reg [37:0]	th7_rd;

	/** Testbench specific **/
	reg [0:55]	test_name;	/* Test name, for ex.: Test_01 */
	reg [0:111]	test_group;	/* Test group name */
	reg		q_set_regs;
	reg [7:0]	q_threads;
	reg		q_wcomb;
	reg		q_aswap;
	reg [23:0]	q_apat;
	reg [23:0]	q_dpat;
	wire [37:0]	shtd_addr = { lsu_wrq_addr, 1'b0 };


	always
		#HCLK clk = !clk;


	/* Set registers values before test */
	task set_regs;
	input [7:0]	threads;	/* Threads enable mask */
	input		wcomb;		/* Enable write combine */
	input		aswap;		/* Swap threads for write combine */
	input [23:0]	apat;		/* Address patterns */
	input [23:0]	dpat;		/* Data pattern */
	begin
		@(posedge clk)
		begin
			q_set_regs <= 1'b1;
			q_threads <= threads;
			q_wcomb <= wcomb;
			q_aswap <= aswap;
			q_apat <= apat;
			q_dpat <= dpat;
		end
		@(posedge clk)
			q_set_regs <= 1'b0;
	end
	endtask


	/* Wait for "posedge clk" */
	task wait_pos_clk;
	input integer j;	/* Number of cycles*/
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
		$dumpvars(0, tb_vxe_vpu_stor_eu);

		clk = 1'b1;
		nrst = 1'b0;

		start <= 1'b0;
		lsu_wrq_rdy <= 1'b1;
		q_set_regs <= 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(1);
		/***********************************************************/

`ifdef TESTS_SINGLE
		@(posedge clk) test_group <= "SINGLE        ";

		/*** Test 01 - Thread 0 is active ****/
		@(posedge clk) test_name <= "Test_01";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000001, 1'b0, 1'b0, 24'hffaa00, 24'hffaa00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 02 - Thread 1 is active ****/
		@(posedge clk) test_name <= "Test_02";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000010, 1'b0, 1'b0, 24'hffaa01, 24'hffaa01);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 03 - Thread 2 is active ****/
		@(posedge clk) test_name <= "Test_03";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000100, 1'b0, 1'b0, 24'hffaa02, 24'hffaa02);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 04 - Thread 3 is active ****/
		@(posedge clk) test_name <= "Test_04";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00001000, 1'b0, 1'b0, 24'hffaa03, 24'hffaa03);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 05 - Thread 4 is active ****/
		@(posedge clk) test_name <= "Test_05";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00010000, 1'b0, 1'b0, 24'hffaa04, 24'hffaa04);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 06 - Thread 5 is active ****/
		@(posedge clk) test_name <= "Test_06";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00100000, 1'b0, 1'b0, 24'hffaa05, 24'hffaa05);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 07 - Thread 6 is active ****/
		@(posedge clk) test_name <= "Test_07";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b01000000, 1'b0, 1'b0, 24'hffaa06, 24'hffaa06);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 08 - Thread 7 is active ****/
		@(posedge clk) test_name <= "Test_08";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b10000000, 1'b0, 1'b0, 24'hffaa07, 24'hffaa07);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif



`ifdef TESTS_SINGLE_NA
		@(posedge clk) test_group <= "SINGLE_NA     ";

		/*** Test 09 - Thread 0 is active ****/
		@(posedge clk) test_name <= "Test_09";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000001, 1'b0, 1'b1, 24'hffee00, 24'hffee00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 10 - Thread 1 is active ****/
		@(posedge clk) test_name <= "Test_10";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000010, 1'b0, 1'b1, 24'hffee01, 24'hffee01);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 11 - Thread 2 is active ****/
		@(posedge clk) test_name <= "Test_11";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000100, 1'b0, 1'b1, 24'hffee02, 24'hffee02);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 12 - Thread 3 is active ****/
		@(posedge clk) test_name <= "Test_12";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00001000, 1'b0, 1'b1, 24'hffee03, 24'hffee03);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 13 - Thread 4 is active ****/
		@(posedge clk) test_name <= "Test_13";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00010000, 1'b0, 1'b1, 24'hffee04, 24'hffee04);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 14 - Thread 5 is active ****/
		@(posedge clk) test_name <= "Test_14";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00100000, 1'b0, 1'b1, 24'hffee05, 24'hffee05);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 15 - Thread 6 is active ****/
		@(posedge clk) test_name <= "Test_15";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b01000000, 1'b0, 1'b1, 24'hffee06, 24'hffee06);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 16 - Thread 7 is active ****/
		@(posedge clk) test_name <= "Test_16";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b10000000, 1'b0, 1'b1, 24'hffee07, 24'hffee07);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif



`ifdef TESTS_WC_GROUPS
		@(posedge clk) test_group <= "WC_GROUPS     ";

		/*** Test 17 - Write combine 0 ****/
		@(posedge clk) test_name <= "Test_17";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000011, 1'b1, 1'b0, 24'hffbb00, 24'hffbb00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 18 - Write combine 1 ****/
		@(posedge clk) test_name <= "Test_18";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00001100, 1'b1, 1'b0, 24'hffbb01, 24'hffbb01);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 19 - Write combine 2 ****/
		@(posedge clk) test_name <= "Test_19";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00110000, 1'b1, 1'b0, 24'hffbb02, 24'hffbb02);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 20 - Write combine 3 ****/
		@(posedge clk) test_name <= "Test_20";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11000000, 1'b1, 1'b0, 24'hffbb03, 24'hffbb03);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif



`ifdef TESTS_WC_GROUPS_SWAP
		@(posedge clk) test_group <= "WC_GROUPS_SWAP";

		/*** Test 21 - Write combine 0 ****/
		@(posedge clk) test_name <= "Test_21";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00000011, 1'b1, 1'b1, 24'hffcc00, 24'hffcc00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 22 - Write combine 1 ****/
		@(posedge clk) test_name <= "Test_22";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00001100, 1'b1, 1'b1, 24'hffcc01, 24'hffcc01);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 23 - Write combine 2 ****/
		@(posedge clk) test_name <= "Test_23";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b00110000, 1'b1, 1'b1, 24'hffcc02, 24'hffcc02);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 24 - Write combine 3 ****/
		@(posedge clk) test_name <= "Test_24";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11000000, 1'b1, 1'b1, 24'hffcc03, 24'hffcc03);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif



`ifdef TESTS_ALL_NO_WC
		@(posedge clk) test_group <= "ALL_NO_WC     ";

		/*** Test 25 - All threads active (no WC) ****/
		@(posedge clk) test_name <= "Test_25";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11111111, 1'b0, 1'b0, 24'hffdd00, 24'hffdd00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif



`ifdef TESTS_ALL_WC
		@(posedge clk) test_group <= "ALL_WC        ";

		/*** Test 26 - All threads active (WC) ****/
		@(posedge clk) test_name <= "Test_26";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11111111, 1'b1, 1'b0, 24'hffee00, 24'hffee00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif



`ifdef TESTS_ALL_WC_SWAP
		@(posedge clk) test_group <= "ALL_WC_SWAP   ";

		/*** Test 27 - All threads active (swapped WC) ****/
		@(posedge clk) test_name <= "Test_27";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11111111, 1'b1, 1'b1, 24'hffff00, 24'hffff00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif



`ifdef TESTS_DST_BUSY_NO_WC
		@(posedge clk) test_group <= "DST_BUSY_NO_WC";

		/*** Test 28 - Destination busy (no WC) ****/
		@(posedge clk) test_name <= "Test_28";

		@(posedge clk) lsu_wrq_rdy <= 1'b0;

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11111111, 1'b0, 1'b0, 24'hffaa00, 24'hffaa00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk(12);

		@(posedge clk) lsu_wrq_rdy <= 1'b1;


		wait_pos_clk(12);
`endif



`ifdef TESTS_DST_BUSY_WC
		@(posedge clk) test_group <= "DST_BUSY_WC   ";

		/*** Test 29 - Destination busy (WC) ****/
		@(posedge clk) test_name <= "Test_29";

		@(posedge clk) lsu_wrq_rdy <= 1'b0;

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11111111, 1'b1, 1'b0, 24'hffbb00, 24'hffbb00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk(12);

		@(posedge clk) lsu_wrq_rdy <= 1'b1;


		wait_pos_clk(12);
`endif



`ifdef TESTS_ALL_BUT_ONE
		@(posedge clk) test_group <= "ALL_BUT_ONE   ";

		/*** Test 30 - Even thread is disabled (no WC) ****/
		@(posedge clk) test_name <= "Test_30";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11111011, 1'b0, 1'b0, 24'hffaa00, 24'hffaa00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 31 - Odd thread is disabled (no WC) ****/
		@(posedge clk) test_name <= "Test_31";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11110111, 1'b0, 1'b0, 24'hffbb00, 24'hffbb00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 32 - Two threads are disabled (no WC) ****/
		@(posedge clk) test_name <= "Test_32";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11110011, 1'b0, 1'b0, 24'hffcc00, 24'hffcc00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 33 - Even thread is disabled (WC) ****/
		@(posedge clk) test_name <= "Test_33";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11111011, 1'b1, 1'b0, 24'hffdd00, 24'hffdd00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 34 - Odd thread is disabled (WC) ****/
		@(posedge clk) test_name <= "Test_34";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11110111, 1'b1, 1'b0, 24'hffee00, 24'hffee00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);


		/*** Test 35 - Two threads are disabled (WC) ****/
		@(posedge clk) test_name <= "Test_35";

		/*        threads,   wcomb, aswap,  apat,      dpat */
		set_regs(8'b11110011, 1'b1, 1'b0, 24'hffff00, 24'hffff00);

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;


		wait_pos_clk(12);
`endif


		wait_pos_clk(32);

		#500 $finish;
	end


	/* Store execution unit */
	vxe_vpu_stor_eu stor_eu(
		.clk(clk),
		.nrst(nrst),
		/* Control unit interface */
		.i_start(start),
		.o_busy(busy),
		/* LSU interface */
		.i_lsu_wrq_rdy(lsu_wrq_rdy),
		.o_lsu_wrq_wr(lsu_wrq_wr),
		.o_lsu_wrq_th(lsu_wrq_th),
		.o_lsu_wrq_addr(lsu_wrq_addr),
		.o_lsu_wrq_wen(lsu_wrq_wen),
		.o_lsu_wrq_data(lsu_wrq_data),
		/* Register values */
		.i_th0_acc(th0_acc),
		.i_th0_en(th0_en),
		.i_th0_rd(th0_rd),
		.i_th1_acc(th1_acc),
		.i_th1_en(th1_en),
		.i_th1_rd(th1_rd),
		.i_th2_acc(th2_acc),
		.i_th2_en(th2_en),
		.i_th2_rd(th2_rd),
		.i_th3_acc(th3_acc),
		.i_th3_en(th3_en),
		.i_th3_rd(th3_rd),
		.i_th4_acc(th4_acc),
		.i_th4_en(th4_en),
		.i_th4_rd(th4_rd),
		.i_th5_acc(th5_acc),
		.i_th5_en(th5_en),
		.i_th5_rd(th5_rd),
		.i_th6_acc(th6_acc),
		.i_th6_en(th6_en),
		.i_th6_rd(th6_rd),
		.i_th7_acc(th7_acc),
		.i_th7_en(th7_en),
		.i_th7_rd(th7_rd)
	);



/************************** Test setup logic **********************************/

	always @(posedge clk)
	begin
		if(q_set_regs)
		begin
			/*** WC0 ***/

			th0_acc <= { q_dpat, 8'h00 };
			th0_en <= q_threads[0];
			th0_rd <= {
				6'b111111,
				q_apat,
				{
					4'h0,
					3'b000,
					q_wcomb ? q_aswap : q_aswap
				}
			};

			th1_acc <= { q_dpat, 8'h01 };
			th1_en <= q_threads[1];
			th1_rd <= {
				6'b111111,
				q_apat,
				{
					q_wcomb ? 4'h0 : 4'h1,
					3'b000,
					q_wcomb ? ~q_aswap : q_aswap
				}
			};

			/*** WC1 ***/

			th2_acc <= { q_dpat, 8'h02 };
			th2_en <= q_threads[2];
			th2_rd <= {
				6'b111111,
				q_apat,
				{
					4'h2,
					3'b000,
					q_wcomb ? q_aswap : q_aswap
				}
			};

			th3_acc <= { q_dpat, 8'h03 };
			th3_en <= q_threads[3];
			th3_rd <= {
				6'b111111,
				q_apat,
				{
					q_wcomb ? 4'h2 : 4'h3,
					3'b000,
					q_wcomb ? ~q_aswap : q_aswap
				}
			};

			/*** WC2 ***/

			th4_acc <= { q_dpat, 8'h04 };
			th4_en <= q_threads[4];
			th4_rd <= {
				6'b111111,
				q_apat,
				{
					4'h4,
					3'b000,
					q_wcomb ? q_aswap : q_aswap
				}
			};

			th5_acc <= { q_dpat, 8'h05 };
			th5_en <= q_threads[5];
			th5_rd <= {
				6'b111111,
				q_apat,
				{
					q_wcomb ? 4'h4 : 4'h5,
					3'b000,
					q_wcomb ? ~q_aswap : q_aswap
				}
			};

			/*** WC3 ***/

			th6_acc <= { q_dpat, 8'h06 };
			th6_en <= q_threads[6];
			th6_rd <= {
				6'b111111,
				q_apat,
				{
					4'h6,
					3'b000,
					q_wcomb ? q_aswap : q_aswap
				}
			};

			th7_acc <= { q_dpat, 8'h07 };
			th7_en <= q_threads[7];
			th7_rd <= {
				6'b111111,
				q_apat,
				{
					q_wcomb ? 4'h6 : 4'h7,
					3'b000,
					q_wcomb ? ~q_aswap : q_aswap
				}
			};
		end
	end


endmodule /* tb_vxe_vpu_stor_eu */
