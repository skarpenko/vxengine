/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
 * Testbench for VxE vector unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


/* Test groups */
`define TEST_THREAD_0
`define TEST_THREAD_1
`define TEST_THREAD_2
`define TEST_THREAD_3
`define TEST_THREAD_4
`define TEST_THREAD_5
`define TEST_THREAD_6
`define TEST_THREAD_7
`define TEST_THREAD_ALL		/* All threads */
`define TEST_THREAD_ALL_WC	/* All threads write combine case */


module tb_vxe_vec_unit();
`include "vxe_ctrl_unit_cmds.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;

	/* Memory request channel */
	wire		rqa_vld;
	wire [43:0]	rqa;
	reg		rqa_rd;
	wire		fifo_rqa_rdy;
	wire [43:0]	fifo_rqa;
	wire		fifo_rqa_wr;
	wire		rqd_vld;
	wire [71:0]	rqd;
	reg		rqd_rd;
	wire		fifo_rqd_rdy;
	wire [71:0]	fifo_rqd;
	wire		fifo_rqd_wr;
	/* Memory response channel */
	wire		rss_rdy;
	reg [8:0]	rss;
	reg		rss_wr;
	wire		fifo_rss_vld;
	wire [8:0]	fifo_rss;
	wire		fifo_rss_rd;
	wire		rsd_rdy;
	reg [63:0]	rsd;
	reg		rsd_wr;
	wire		fifo_rsd_vld;
	wire [63:0]	fifo_rsd;
	wire		fifo_rsd_rd;
	/* Control signals */
	reg		start;
	wire		busy;
	wire		err;
	reg		cmd_sel;
	wire		cmd_ack;
	reg [4:0]	cmd_op;
	reg [2:0]	cmd_th;
	reg [47:0]	cmd_pl;

	/* Misc signals */
	reg [0:55]	test_name;


	always
		#HCLK clk = !clk;


	/* Wait for "posedge clk" */
	task wait_pos_clk;
	input integer j;	/* Number of cycles*/
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


	/* Send VPU command */
	task send_cmd;
	input [4:0]	op;
	input [2:0]	th;
	input [47:0]	pl;
	begin
		@(posedge clk)
		begin
			cmd_sel <= 1'b1;
			cmd_op <= op;
			cmd_th <= th;
			cmd_pl <= pl;
		end
		@(posedge clk)
			cmd_sel <= 1'b0;
		wait_pos_clk(2);	/* Wait to make sure the command acknowledged */
	end
	endtask


	/* Start / re-enable VPU */
	task re_enable;
	begin
		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vec_unit);

		clk = 1;
		nrst = 0;

		start = 0;
		cmd_sel = 0;
		cmd_op = 0;
		cmd_th = 0;
		cmd_pl = 0;
		rqa_rd = 0;
		rqd_rd = 0;
		rss_wr = 0;
		rsd_wr = 0;

		wait_pos_clk(3);

		nrst = 1;

		wait_pos_clk(3);

		/**********************************************/


		re_enable();

`ifdef TEST_THREAD_0
		/* Test 1 - Thread 0 */
		test("Test 1 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h0, 48'h0000_4000_0000);
		send_cmd(CU_CMD_SETVL,  3'h0, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h0, 48'h0000_0000_1000);
		send_cmd(CU_CMD_SETRT,  3'h0, 48'h0000_0000_1000);
		send_cmd(CU_CMD_SETRD,  3'h0, 48'h0000_0000_1000);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 1 ", 32);
`endif


`ifdef TEST_THREAD_1
		/* Test 2 - Thread 1 */
		test("Test 2 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h1, 48'h0000_4100_0000);
		send_cmd(CU_CMD_SETVL,  3'h1, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h1, 48'h0000_0000_1100);
		send_cmd(CU_CMD_SETRT,  3'h1, 48'h0000_0000_1100);
		send_cmd(CU_CMD_SETRD,  3'h1, 48'h0000_0000_1100);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 2 ", 32);
`endif


`ifdef TEST_THREAD_2
		/* Test 3 - Thread 2 */
		test("Test 3 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h2, 48'h0000_4200_0000);
		send_cmd(CU_CMD_SETVL,  3'h2, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h2, 48'h0000_0000_1200);
		send_cmd(CU_CMD_SETRT,  3'h2, 48'h0000_0000_1200);
		send_cmd(CU_CMD_SETRD,  3'h2, 48'h0000_0000_1200);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 3 ", 32);
`endif


`ifdef TEST_THREAD_3
		/* Test 4 - Thread 3 */
		test("Test 4 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h3, 48'h0000_4300_0000);
		send_cmd(CU_CMD_SETVL,  3'h3, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h3, 48'h0000_0000_1300);
		send_cmd(CU_CMD_SETRT,  3'h3, 48'h0000_0000_1300);
		send_cmd(CU_CMD_SETRD,  3'h3, 48'h0000_0000_1300);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 4 ", 32);
`endif


`ifdef TEST_THREAD_4
		/* Test 5 - Thread 4 */
		test("Test 5 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h4, 48'h0000_4400_0000);
		send_cmd(CU_CMD_SETVL,  3'h4, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h4, 48'h0000_0000_1400);
		send_cmd(CU_CMD_SETRT,  3'h4, 48'h0000_0000_1400);
		send_cmd(CU_CMD_SETRD,  3'h4, 48'h0000_0000_1400);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 5 ", 32);
`endif


`ifdef TEST_THREAD_5
		/* Test 6 - Thread 5 */
		test("Test 6 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h5, 48'h0000_4500_0000);
		send_cmd(CU_CMD_SETVL,  3'h5, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h5, 48'h0000_0000_1500);
		send_cmd(CU_CMD_SETRT,  3'h5, 48'h0000_0000_1500);
		send_cmd(CU_CMD_SETRD,  3'h5, 48'h0000_0000_1500);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 6 ", 32);
`endif


`ifdef TEST_THREAD_6
		/* Test 7 - Thread 6 */
		test("Test 7 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h6, 48'h0000_4600_0000);
		send_cmd(CU_CMD_SETVL,  3'h6, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h6, 48'h0000_0000_1600);
		send_cmd(CU_CMD_SETRT,  3'h6, 48'h0000_0000_1600);
		send_cmd(CU_CMD_SETRD,  3'h6, 48'h0000_0000_1600);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 7 ", 32);
`endif


`ifdef TEST_THREAD_7
		/* Test 8 - Thread 7 */
		test("Test 8 ", 0);

		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0000);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0000);

		send_cmd(CU_CMD_SETACC, 3'h7, 48'h0000_4700_0000);
		send_cmd(CU_CMD_SETVL,  3'h7, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h7, 48'h0000_0000_1700);
		send_cmd(CU_CMD_SETRT,  3'h7, 48'h0000_0000_1700);
		send_cmd(CU_CMD_SETRD,  3'h7, 48'h0000_0000_1700);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 8 ", 32);
`endif


`ifdef TEST_THREAD_ALL
		/* Test 9 - All threads */
		test("Test 9 ", 0);

		send_cmd(CU_CMD_SETACC, 3'h0, 48'h0000_4000_0000);
		send_cmd(CU_CMD_SETVL,  3'h0, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h0, 48'h0000_0000_1000);
		send_cmd(CU_CMD_SETRT,  3'h0, 48'h0000_0000_1000);
		send_cmd(CU_CMD_SETRD,  3'h0, 48'h0000_0000_1000);

		send_cmd(CU_CMD_SETACC, 3'h1, 48'h0000_4100_0000);
		send_cmd(CU_CMD_SETVL,  3'h1, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h1, 48'h0000_0000_1100);
		send_cmd(CU_CMD_SETRT,  3'h1, 48'h0000_0000_1100);
		send_cmd(CU_CMD_SETRD,  3'h1, 48'h0000_0000_1100);

		send_cmd(CU_CMD_SETACC, 3'h2, 48'h0000_4200_0000);
		send_cmd(CU_CMD_SETVL,  3'h2, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h2, 48'h0000_0000_1200);
		send_cmd(CU_CMD_SETRT,  3'h2, 48'h0000_0000_1200);
		send_cmd(CU_CMD_SETRD,  3'h2, 48'h0000_0000_1200);

		send_cmd(CU_CMD_SETACC, 3'h3, 48'h0000_4300_0000);
		send_cmd(CU_CMD_SETVL,  3'h3, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h3, 48'h0000_0000_1300);
		send_cmd(CU_CMD_SETRT,  3'h3, 48'h0000_0000_1300);
		send_cmd(CU_CMD_SETRD,  3'h3, 48'h0000_0000_1300);

		send_cmd(CU_CMD_SETACC, 3'h4, 48'h0000_4400_0000);
		send_cmd(CU_CMD_SETVL,  3'h4, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h4, 48'h0000_0000_1400);
		send_cmd(CU_CMD_SETRT,  3'h4, 48'h0000_0000_1400);
		send_cmd(CU_CMD_SETRD,  3'h4, 48'h0000_0000_1400);

		send_cmd(CU_CMD_SETACC, 3'h5, 48'h0000_4500_0000);
		send_cmd(CU_CMD_SETVL,  3'h5, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h5, 48'h0000_0000_1500);
		send_cmd(CU_CMD_SETRT,  3'h5, 48'h0000_0000_1500);
		send_cmd(CU_CMD_SETRD,  3'h5, 48'h0000_0000_1500);

		send_cmd(CU_CMD_SETACC, 3'h6, 48'h0000_4600_0000);
		send_cmd(CU_CMD_SETVL,  3'h6, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h6, 48'h0000_0000_1600);
		send_cmd(CU_CMD_SETRT,  3'h6, 48'h0000_0000_1600);
		send_cmd(CU_CMD_SETRD,  3'h6, 48'h0000_0000_1600);

		send_cmd(CU_CMD_SETACC, 3'h7, 48'h0000_4700_0000);
		send_cmd(CU_CMD_SETVL,  3'h7, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h7, 48'h0000_0000_1700);
		send_cmd(CU_CMD_SETRT,  3'h7, 48'h0000_0000_1700);
		send_cmd(CU_CMD_SETRD,  3'h7, 48'h0000_0000_1700);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 9 ", 32);
`endif


`ifdef TEST_THREAD_ALL_WC
		/* Test 10 - All threads (Write combine) */
		test("Test 10", 0);

		send_cmd(CU_CMD_SETACC, 3'h0, 48'h0000_4000_0000);
		send_cmd(CU_CMD_SETVL,  3'h0, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h0, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h0, 48'h0000_0000_1000);
		send_cmd(CU_CMD_SETRT,  3'h0, 48'h0000_0000_1000);
		send_cmd(CU_CMD_SETRD,  3'h0, 48'h0000_0000_1000);

		send_cmd(CU_CMD_SETACC, 3'h1, 48'h0000_4100_0000);
		send_cmd(CU_CMD_SETVL,  3'h1, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h1, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h1, 48'h0000_0000_1100);
		send_cmd(CU_CMD_SETRT,  3'h1, 48'h0000_0000_1100);
		send_cmd(CU_CMD_SETRD,  3'h1, 48'h0000_0000_1001);

		send_cmd(CU_CMD_SETACC, 3'h2, 48'h0000_4200_0000);
		send_cmd(CU_CMD_SETVL,  3'h2, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h2, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h2, 48'h0000_0000_1200);
		send_cmd(CU_CMD_SETRT,  3'h2, 48'h0000_0000_1200);
		send_cmd(CU_CMD_SETRD,  3'h2, 48'h0000_0000_1002);

		send_cmd(CU_CMD_SETACC, 3'h3, 48'h0000_4300_0000);
		send_cmd(CU_CMD_SETVL,  3'h3, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h3, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h3, 48'h0000_0000_1300);
		send_cmd(CU_CMD_SETRT,  3'h3, 48'h0000_0000_1300);
		send_cmd(CU_CMD_SETRD,  3'h3, 48'h0000_0000_1003);

		send_cmd(CU_CMD_SETACC, 3'h4, 48'h0000_4400_0000);
		send_cmd(CU_CMD_SETVL,  3'h4, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h4, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h4, 48'h0000_0000_1400);
		send_cmd(CU_CMD_SETRT,  3'h4, 48'h0000_0000_1400);
		send_cmd(CU_CMD_SETRD,  3'h4, 48'h0000_0000_1004);

		send_cmd(CU_CMD_SETACC, 3'h5, 48'h0000_4500_0000);
		send_cmd(CU_CMD_SETVL,  3'h5, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h5, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h5, 48'h0000_0000_1500);
		send_cmd(CU_CMD_SETRT,  3'h5, 48'h0000_0000_1500);
		send_cmd(CU_CMD_SETRD,  3'h5, 48'h0000_0000_1005);

		send_cmd(CU_CMD_SETACC, 3'h6, 48'h0000_4600_0000);
		send_cmd(CU_CMD_SETVL,  3'h6, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h6, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h6, 48'h0000_0000_1600);
		send_cmd(CU_CMD_SETRT,  3'h6, 48'h0000_0000_1600);
		send_cmd(CU_CMD_SETRD,  3'h6, 48'h0000_0000_1006);

		send_cmd(CU_CMD_SETACC, 3'h7, 48'h0000_4700_0000);
		send_cmd(CU_CMD_SETVL,  3'h7, 48'h0000_0000_0010);
		send_cmd(CU_CMD_SETEN,  3'h7, 48'h0000_0000_0001);
		send_cmd(CU_CMD_SETRS,  3'h7, 48'h0000_0000_1700);
		send_cmd(CU_CMD_SETRT,  3'h7, 48'h0000_0000_1700);
		send_cmd(CU_CMD_SETRD,  3'h7, 48'h0000_0000_1007);

		send_cmd(CU_CMD_PROD,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_ACTF,   3'h0, 48'h0000_0000_0000);
		send_cmd(CU_CMD_STORE,  3'h0, 48'h0000_0000_0000);

		wait_pos_clk(256);
		test("Done 10", 32);
`endif


		#500 $finish;
	end


	/* Vector unit instance */
	vxe_vec_unit #(
		.CLIENT_ID(0)
	) vec_unit(
		.clk(clk),
		.nrst(nrst),
		.i_rqa_rdy(fifo_rqa_rdy),
		.o_rqa(fifo_rqa),
		.o_rqa_wr(fifo_rqa_wr),
		.i_rqd_rdy(fifo_rqd_rdy),
		.o_rqd(fifo_rqd),
		.o_rqd_wr(fifo_rqd_wr),
		.i_rss_vld(fifo_rss_vld),
		.i_rss(fifo_rss),
		.o_rss_rd(fifo_rss_rd),
		.i_rsd_vld(fifo_rsd_vld),
		.i_rsd(fifo_rsd),
		.o_rsd_rd(fifo_rsd_rd),
		.i_start(start),
		.o_busy(busy),
		.o_err(err),
		.i_cmd_sel(cmd_sel),
		.o_cmd_ack(cmd_ack),
		.i_cmd_op(cmd_op),
		.i_cmd_th(cmd_th),
		.i_cmd_pl(cmd_pl)
	);

	/* FIFO for outgoing requests */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) req_a (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqa),
		.data_out(rqa),
		.rd(rqa_rd),
		.wr(fifo_rqa_wr),
		.in_rdy(fifo_rqa_rdy),
		.out_vld(rqa_vld)
	);

	/* FIFO for outgoing requests data */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) req_d (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqd),
		.data_out(rqd),
		.rd(rqd_rd),
		.wr(fifo_rqd_wr),
		.in_rdy(fifo_rqd_rdy),
		.out_vld(rqd_vld)
	);

	/* FIFO for incoming response status */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) resp_s (
		.clk(clk),
		.nrst(nrst),
		.data_in(rss),
		.data_out(fifo_rss),
		.rd(fifo_rss_rd),
		.wr(rss_wr),
		.in_rdy(rss_rdy),
		.out_vld(fifo_rss_vld)
	);

	/* FIFO for incoming response data */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resp_d (
		.clk(clk),
		.nrst(nrst),
		.data_in(rsd),
		.data_out(fifo_rsd),
		.rd(fifo_rsd_rd),
		.wr(rsd_wr),
		.in_rdy(rsd_rdy),
		.out_vld(fifo_rsd_vld)
	);


	/**** Memory traffic handling ****/

	/* Active requests tracking */
	reg [6:0] reqs[0:255];	/* Requests FIFO (Txn Id + RnW) */
	reg [8:0] reqs_wp;	/* Write pointer */
	reg [8:0] reqs_rp;	/* Read pointer */
	/* Previous read pointer */
	wire [8:0] reqs_pre_rp = reqs_rp - 1'b1;
	/* Requests FIFO empty */
	wire reqs_empty = (reqs_rp[7:0] == reqs_wp[7:0]) &&
		(reqs_rp[8] == reqs_wp[8]);
	/* Requests FIFO full */
	wire reqs_full = (reqs_rp[7:0] == reqs_wp[7:0]) &&
		(reqs_rp[8] != reqs_wp[8]);
	wire reqs_pre_full = (reqs_pre_rp[7:0] == reqs_wp[7:0]) &&
		(reqs_pre_rp[8] != reqs_wp[8]);
	/* Requests FIFO stall */
	wire reqs_stall = reqs_full || reqs_pre_full;


	/* Requests receiving FSM */
	reg fsm_recv;

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			fsm_recv <= 1'b0;
			reqs_wp <= 9'h0;
			rqa_rd <= 1'b0;
		end
		else if(fsm_recv == 1'b0)
		begin
			/*
			 * Always drain request data FIFO.
			*/
			rqd_rd <= 1'b1;

			if(!reqs_stall)
			begin
				fsm_recv <= 1'b1;
				rqa_rd <= 1'b1;
			end
		end
		else if(fsm_recv == 1'b1)
		begin
			if(rqa_vld)
			begin
				reqs[reqs_wp[7:0]] <= rqa[43:37];	/* Txn Id + RnW bit */
				reqs_wp <= reqs_wp + 1'b1;
			end

			if(reqs_stall)
			begin
				fsm_recv <= 1'b0;
				rqa_rd <= 1'b0;
			end
		end
	end


	/* Responses sending FSM */
	reg fsm_resp;

	wire rnw = reqs[reqs_rp[7:0]][0];		/* RnW */
	wire [5:0] txnid = reqs[reqs_rp[7:0]][6:1];	/* Transaction Id */

	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			fsm_resp <= 1'b0;
			reqs_rp <= 9'h0;
			rss_wr <= 1'b0;
			rsd_wr <= 1'b0;
		end
		else if(fsm_resp == 1'b0)
		begin
			if(!reqs_empty && rnw)
			begin
				rss <= { txnid, rnw, 2'b00 };
				rss_wr <= 1'b1;
				rsd <= 64'h0000;
				rsd_wr <= 1'b1;
				reqs_rp <= reqs_rp + 1'b1;
				fsm_resp <= 1'b1;
			end
			else if(!reqs_empty)
			begin
				rss <= { txnid, rnw, 2'b00 };
				rss_wr <= 1'b1;
				reqs_rp <= reqs_rp + 1'b1;
				fsm_resp <= 1'b1;
			end
		end
		else if(fsm_resp == 1'b1)
		begin
			if(rss_rdy && !reqs_empty && rnw)
			begin
				rss <= { txnid, rnw, 2'b00 };
				rss_wr <= 1'b1;
				rsd <= 64'h0000;
				rsd_wr <= 1'b1;
				reqs_rp <= reqs_rp + 1'b1;
			end
			else if(rss_rdy && !reqs_empty)
			begin
				rss <= { txnid, rnw, 2'b00 };
				rss_wr <= 1'b1;
				rsd_wr <= 1'b0;
				reqs_rp <= reqs_rp + 1'b1;
			end
			else if(rss_rdy)
			begin
				rss_wr <= 1'b0;
				rsd_wr <= 1'b0;
				fsm_resp <= 1'b0;
			end
		end
	end


endmodule /* tb_vxe_vec_unit */
