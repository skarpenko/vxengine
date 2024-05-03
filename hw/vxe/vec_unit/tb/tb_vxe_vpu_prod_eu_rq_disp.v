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
 * Testbench for VxE VPU requests dispatcher unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


/* Test groups */
`define TESTS_ONE_VECTOR	/* One vector only */
`define TESTS_SINGLE_THREAD	/* Single thread (two vectors) */
`define TESTS_ALL_THREADS	/* All threads active */
`define TESTS_LSU_NOT_RDY	/* LSU not ready */
`define TESTS_WE_NOT_RDY	/* WE FIFO(s) not ready */
`define TESTS_ERR_FLUSH		/* FLUSH on error */



module tb_vxe_vpu_prod_eu_rq_disp();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;


	/* Control interface */
	reg		err_flush;
	wire		busy;
	/* Generated address and word enable mask */
	wire		rs0_valid;
	wire [36:0]	rs0_addr;
	wire [1:0]	rs0_we_mask;
	wire		rs0_incr;
	wire		rt0_valid;
	wire [36:0]	rt0_addr;
	wire [1:0]	rt0_we_mask;
	wire		rt0_incr;
	wire		rs1_valid;
	wire [36:0]	rs1_addr;
	wire [1:0]	rs1_we_mask;
	wire		rs1_incr;
	wire		rt1_valid;
	wire [36:0]	rt1_addr;
	wire [1:0]	rt1_we_mask;
	wire		rt1_incr;
	wire		rs2_valid;
	wire [36:0]	rs2_addr;
	wire [1:0]	rs2_we_mask;
	wire		rs2_incr;
	wire		rt2_valid;
	wire [36:0]	rt2_addr;
	wire [1:0]	rt2_we_mask;
	wire		rt2_incr;
	wire		rs3_valid;
	wire [36:0]	rs3_addr;
	wire [1:0]	rs3_we_mask;
	wire		rs3_incr;
	wire		rt3_valid;
	wire [36:0]	rt3_addr;
	wire [1:0]	rt3_we_mask;
	wire		rt3_incr;
	wire		rs4_valid;
	wire [36:0]	rs4_addr;
	wire [1:0]	rs4_we_mask;
	wire		rs4_incr;
	wire		rt4_valid;
	wire [36:0]	rt4_addr;
	wire [1:0]	rt4_we_mask;
	wire		rt4_incr;
	wire		rs5_valid;
	wire [36:0]	rs5_addr;
	wire [1:0]	rs5_we_mask;
	wire		rs5_incr;
	wire		rt5_valid;
	wire [36:0]	rt5_addr;
	wire [1:0]	rt5_we_mask;
	wire		rt5_incr;
	wire		rs6_valid;
	wire [36:0]	rs6_addr;
	wire [1:0]	rs6_we_mask;
	wire		rs6_incr;
	wire		rt6_valid;
	wire [36:0]	rt6_addr;
	wire [1:0]	rt6_we_mask;
	wire		rt6_incr;
	wire		rs7_valid;
	wire [36:0]	rs7_addr;
	wire [1:0]	rs7_we_mask;
	wire		rs7_incr;
	wire		rt7_valid;
	wire [36:0]	rt7_addr;
	wire [1:0]	rt7_we_mask;
	wire		rt7_incr;
	/* Write enable FIFO interface */
	wire [1:0]	rrq_rs0_we_mask;
	wire		rrq_rs0_we_wr;
	wire		rrq_rs0_we_rdy;
	wire [1:0]	rrq_rt0_we_mask;
	wire		rrq_rt0_we_wr;
	wire		rrq_rt0_we_rdy;
	wire [1:0]	rrq_rs1_we_mask;
	wire		rrq_rs1_we_wr;
	wire		rrq_rs1_we_rdy;
	wire [1:0]	rrq_rt1_we_mask;
	wire		rrq_rt1_we_wr;
	wire		rrq_rt1_we_rdy;
	wire [1:0]	rrq_rs2_we_mask;
	wire		rrq_rs2_we_wr;
	wire		rrq_rs2_we_rdy;
	wire [1:0]	rrq_rt2_we_mask;
	wire		rrq_rt2_we_wr;
	wire		rrq_rt2_we_rdy;
	wire [1:0]	rrq_rs3_we_mask;
	wire		rrq_rs3_we_wr;
	wire		rrq_rs3_we_rdy;
	wire [1:0]	rrq_rt3_we_mask;
	wire		rrq_rt3_we_wr;
	wire		rrq_rt3_we_rdy;
	wire [1:0]	rrq_rs4_we_mask;
	wire		rrq_rs4_we_wr;
	wire		rrq_rs4_we_rdy;
	wire [1:0]	rrq_rt4_we_mask;
	wire		rrq_rt4_we_wr;
	wire		rrq_rt4_we_rdy;
	wire [1:0]	rrq_rs5_we_mask;
	wire		rrq_rs5_we_wr;
	wire		rrq_rs5_we_rdy;
	wire [1:0]	rrq_rt5_we_mask;
	wire		rrq_rt5_we_wr;
	wire		rrq_rt5_we_rdy;
	wire [1:0]	rrq_rs6_we_mask;
	wire		rrq_rs6_we_wr;
	wire		rrq_rs6_we_rdy;
	wire [1:0]	rrq_rt6_we_mask;
	wire		rrq_rt6_we_wr;
	wire		rrq_rt6_we_rdy;
	wire [1:0]	rrq_rs7_we_mask;
	wire		rrq_rs7_we_wr;
	wire		rrq_rs7_we_rdy;
	wire [1:0]	rrq_rt7_we_mask;
	wire		rrq_rt7_we_wr;
	wire		rrq_rt7_we_rdy;
	/* LSU interface */
	reg		rrq_rdy;
	wire		rrq_wr;
	wire [2:0]	rrq_th;
	wire [36:0]	rrq_addr;
	wire		rrq_arg;

	/** Address generator connections **/
	reg [37:0]	ag_vaddr[0:16];
	reg [19:0]	ag_vlen[0:16];
	reg		ag_latch[0:16];

	/** Testbench specific **/
	reg [0:55]	test_name;		/* Test name, for ex.: Test_01 */
	reg		rrq_we_rdy[0:16];	/* WE FIFO ready signals */


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


	/* Set vaddr and vlen */
	task set_vaddr_vlen;
	input integer	thr;	/* Thread No. 0 - 7 */
	input integer	arg;	/* Argument Rs=0 / Rt=1 */
	input [37:0]	vaddr;	/* Vector address */
	input [19:0]	vlen;	/* Vector len */
	begin
		@(posedge clk)
		begin
			ag_vaddr[2*thr + arg] <= vaddr;
			ag_vlen[2*thr + arg] <= vlen;
		end
	end
	endtask


	/* Address generator latch control */
	task trig_latch;
	input [15:0]	ltch;
	begin
		@(posedge clk)
		begin
			ag_latch[0] <= ltch[0];
			ag_latch[1] <= ltch[1];
			ag_latch[2] <= ltch[2];
			ag_latch[3] <= ltch[3];
			ag_latch[4] <= ltch[4];
			ag_latch[5] <= ltch[5];
			ag_latch[6] <= ltch[6];
			ag_latch[7] <= ltch[7];
			ag_latch[8] <= ltch[8];
			ag_latch[9] <= ltch[9];
			ag_latch[10] <= ltch[10];
			ag_latch[11] <= ltch[11];
			ag_latch[12] <= ltch[12];
			ag_latch[13] <= ltch[13];
			ag_latch[14] <= ltch[14];
			ag_latch[15] <= ltch[15];
		end

		@(posedge clk)
		begin
			ag_latch[0] <= 1'b0;
			ag_latch[1] <= 1'b0;
			ag_latch[2] <= 1'b0;
			ag_latch[3] <= 1'b0;
			ag_latch[4] <= 1'b0;
			ag_latch[5] <= 1'b0;
			ag_latch[6] <= 1'b0;
			ag_latch[7] <= 1'b0;
			ag_latch[8] <= 1'b0;
			ag_latch[9] <= 1'b0;
			ag_latch[10] <= 1'b0;
			ag_latch[11] <= 1'b0;
			ag_latch[12] <= 1'b0;
			ag_latch[13] <= 1'b0;
			ag_latch[14] <= 1'b0;
			ag_latch[15] <= 1'b0;
		end
	end
	endtask


	/* Set WE FIFOs ready */
	task we_ready;
	input [15:0]	rdy;
	begin
		@(posedge clk)
		begin
			rrq_we_rdy[0] <= rdy[0];
			rrq_we_rdy[1] <= rdy[1];
			rrq_we_rdy[2] <= rdy[2];
			rrq_we_rdy[3] <= rdy[3];
			rrq_we_rdy[4] <= rdy[4];
			rrq_we_rdy[5] <= rdy[5];
			rrq_we_rdy[6] <= rdy[6];
			rrq_we_rdy[7] <= rdy[7];
			rrq_we_rdy[8] <= rdy[8];
			rrq_we_rdy[9] <= rdy[9];
			rrq_we_rdy[10] <= rdy[10];
			rrq_we_rdy[11] <= rdy[11];
			rrq_we_rdy[12] <= rdy[12];
			rrq_we_rdy[13] <= rdy[13];
			rrq_we_rdy[14] <= rdy[14];
			rrq_we_rdy[15] <= rdy[15];
		end
	end
	endtask


	/* Set LSU ready */
	task rrq_ready;
	input	rdy;
	begin
		@(posedge clk)
			rrq_rdy <= rdy;
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


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_prod_eu_rq_disp);

		clk = 1'b1;
		nrst = 1'b0;

		rrq_rdy = 1'b0;
		err_flush = 1'b0;

		trig_latch(16'h0000);
		we_ready(16'h0000);

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(1);
		/***********************************************************/

		/*** Initial config ***/
		we_ready(16'hffff);
		rrq_ready(1'b1);


`ifdef TESTS_ONE_VECTOR
		/*** Test 00 - One vector, thread 0, arg Rs ****/
		test("Test_00", 0);
		set_vaddr_vlen(0, 0, 38'h200000000, 20'h10);
		trig_latch(16'b00_00_00_00_00_00_00_01);
		wait_pos_clk(32);
		test("Done_00", 4);


		/*** Test 01 - One vector, thread 0, arg Rt ****/
		test("Test_01", 0);
		set_vaddr_vlen(0, 1, 38'h200200000, 20'h10);
		trig_latch(16'b00_00_00_00_00_00_00_10);
		wait_pos_clk(32);
		test("Done_01", 4);


		/*** Test 02 - One vector, thread 1, arg Rs ****/
		test("Test_02", 0);
		set_vaddr_vlen(1, 0, 38'h202000000, 20'h10);
		trig_latch(16'b00_00_00_00_00_00_01_00);
		wait_pos_clk(32);
		test("Done_02", 4);


		/*** Test 03 - One vector, thread 1, arg Rt ****/
		test("Test_03", 0);
		set_vaddr_vlen(1, 1, 38'h202200000, 20'h10);
		trig_latch(16'b00_00_00_00_00_00_10_00);
		wait_pos_clk(32);
		test("Done_03", 4);


		/*** Test 04 - One vector, thread 2, arg Rs ****/
		test("Test_04", 0);
		set_vaddr_vlen(2, 0, 38'h204000000, 20'h10);
		trig_latch(16'b00_00_00_00_00_01_00_00);
		wait_pos_clk(32);
		test("Done_04", 4);


		/*** Test 05 - One vector, thread 2, arg Rt ****/
		test("Test_05", 0);
		set_vaddr_vlen(2, 1, 38'h204200000, 20'h10);
		trig_latch(16'b00_00_00_00_00_10_00_00);
		wait_pos_clk(32);
		test("Done_05", 4);


		/*** Test 06 - One vector, thread 3, arg Rs ****/
		test("Test_06", 0);
		set_vaddr_vlen(3, 0, 38'h206000000, 20'h10);
		trig_latch(16'b00_00_00_00_01_00_00_00);
		wait_pos_clk(32);
		test("Done_06", 4);


		/*** Test 07 - One vector, thread 3, arg Rt ****/
		test("Test_07", 0);
		set_vaddr_vlen(3, 1, 38'h206200000, 20'h10);
		trig_latch(16'b00_00_00_00_10_00_00_00);
		wait_pos_clk(32);
		test("Done_07", 4);


		/*** Test 08 - One vector, thread 4, arg Rs ****/
		test("Test_08", 0);
		set_vaddr_vlen(4, 0, 38'h208000000, 20'h10);
		trig_latch(16'b00_00_00_01_00_00_00_00);
		wait_pos_clk(32);
		test("Done_08", 4);


		/*** Test 09 - One vector, thread 4, arg Rt ****/
		test("Test_09", 0);
		set_vaddr_vlen(4, 1, 38'h208200000, 20'h10);
		trig_latch(16'b00_00_00_10_00_00_00_00);
		wait_pos_clk(32);
		test("Done_09", 4);


		/*** Test 0A - One vector, thread 5, arg Rs ****/
		test("Test_0A", 0);
		set_vaddr_vlen(5, 0, 38'h20A000000, 20'h10);
		trig_latch(16'b00_00_01_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_0A", 4);


		/*** Test 0B - One vector, thread 5, arg Rt ****/
		test("Test_0B", 0);
		set_vaddr_vlen(5, 1, 38'h20A200000, 20'h10);
		trig_latch(16'b00_00_10_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_0B", 4);


		/*** Test 0C - One vector, thread 6, arg Rs ****/
		test("Test_0C", 0);
		set_vaddr_vlen(6, 0, 38'h20C000000, 20'h10);
		trig_latch(16'b00_01_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_0C", 4);


		/*** Test 0D - One vector, thread 6, arg Rt ****/
		test("Test_0D", 0);
		set_vaddr_vlen(6, 1, 38'h20C200000, 20'h10);
		trig_latch(16'b00_10_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_0D", 4);


		/*** Test 0E - One vector, thread 7, arg Rs ****/
		test("Test_0E", 0);
		set_vaddr_vlen(7, 0, 38'h20E000000, 20'h10);
		trig_latch(16'b01_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_0E", 4);


		/*** Test 0F - One vector, thread 7, arg Rt ****/
		test("Test_0F", 0);
		set_vaddr_vlen(7, 1, 38'h20E200000, 20'h10);
		trig_latch(16'b10_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_0F", 4);
`endif



`ifdef TESTS_SINGLE_THREAD
		/*** Test 10 - Single thread, thread 0 ****/
		test("Test_10", 0);
		set_vaddr_vlen(0, 0, 38'h200000000, 20'h10);
		set_vaddr_vlen(0, 1, 38'h200200000, 20'h10);
		trig_latch(16'b00_00_00_00_00_00_00_11);
		wait_pos_clk(32 + 0*16);
		test("Done_10", 4);


		/*** Test 11 - Single thread, thread 1 ****/
		test("Test_11", 0);
		set_vaddr_vlen(1, 0, 38'h202000000, 20'h10);
		set_vaddr_vlen(1, 1, 38'h202200000, 20'h10);
		trig_latch(16'b00_00_00_00_00_00_11_00);
		wait_pos_clk(32 + 1*16);
		test("Done_11", 4);


		/*** Test 12 - Single thread, thread 2 ****/
		test("Test_12", 0);
		set_vaddr_vlen(2, 0, 38'h204000000, 20'h10);
		set_vaddr_vlen(2, 1, 38'h204200000, 20'h10);
		trig_latch(16'b00_00_00_00_00_11_00_00);
		wait_pos_clk(32 + 2*16);
		test("Done_12", 4);


		/*** Test 13 - Single thread, thread 3 ****/
		test("Test_13", 0);
		set_vaddr_vlen(3, 0, 38'h206000000, 20'h10);
		set_vaddr_vlen(3, 1, 38'h206200000, 20'h10);
		trig_latch(16'b00_00_00_00_11_00_00_00);
		wait_pos_clk(32 + 3*16);
		test("Done_13", 4);


		/*** Test 14 - Single thread, thread 4 ****/
		test("Test_14", 0);
		set_vaddr_vlen(4, 0, 38'h208000000, 20'h10);
		set_vaddr_vlen(4, 1, 38'h208200000, 20'h10);
		trig_latch(16'b00_00_00_11_00_00_00_00);
		wait_pos_clk(32 + 4*16);
		test("Done_14", 4);


		/*** Test 15 - Single thread, thread 5 ****/
		test("Test_15", 0);
		set_vaddr_vlen(5, 0, 38'h20A000000, 20'h10);
		set_vaddr_vlen(5, 1, 38'h20A200000, 20'h10);
		trig_latch(16'b00_00_11_00_00_00_00_00);
		wait_pos_clk(32 + 5*16);
		test("Done_15", 4);


		/*** Test 16 - Single thread, thread 6 ****/
		test("Test_16", 0);
		set_vaddr_vlen(6, 0, 38'h20C000000, 20'h10);
		set_vaddr_vlen(6, 1, 38'h20C200000, 20'h10);
		trig_latch(16'b00_11_00_00_00_00_00_00);
		wait_pos_clk(32 + 6*16);
		test("Done_16", 4);


		/*** Test 17 - Single thread, thread 7 ****/
		test("Test_17", 0);
		set_vaddr_vlen(7, 0, 38'h20E000000, 20'h10);
		set_vaddr_vlen(7, 1, 38'h20E200000, 20'h10);
		trig_latch(16'b11_00_00_00_00_00_00_00);
		wait_pos_clk(32 + 7*16);
		test("Done_17", 4);
`endif



`ifdef TESTS_ALL_THREADS
		/*** Test 18 - All threads ****/
		test("Test_18", 0);
		set_vaddr_vlen(0, 0, 38'h200000000, 20'h10);
		set_vaddr_vlen(0, 1, 38'h200200000, 20'h10);
		set_vaddr_vlen(1, 0, 38'h202000000, 20'h10);
		set_vaddr_vlen(1, 1, 38'h202200000, 20'h10);
		set_vaddr_vlen(2, 0, 38'h204000000, 20'h10);
		set_vaddr_vlen(2, 1, 38'h204200000, 20'h10);
		set_vaddr_vlen(3, 0, 38'h206000000, 20'h10);
		set_vaddr_vlen(3, 1, 38'h206200000, 20'h10);
		set_vaddr_vlen(4, 0, 38'h208000000, 20'h10);
		set_vaddr_vlen(4, 1, 38'h208200000, 20'h10);
		set_vaddr_vlen(5, 0, 38'h20A000000, 20'h10);
		set_vaddr_vlen(5, 1, 38'h20A200000, 20'h10);
		set_vaddr_vlen(6, 0, 38'h20C000000, 20'h10);
		set_vaddr_vlen(6, 1, 38'h20C200000, 20'h10);
		set_vaddr_vlen(7, 0, 38'h20E000000, 20'h10);
		set_vaddr_vlen(7, 1, 38'h20E200000, 20'h10);
		trig_latch(16'b11_11_11_11_11_11_11_11);
		wait_pos_clk(160);
		test("Done_18", 4);
`endif



`ifdef TESTS_LSU_NOT_RDY
		/*** Test 19 - LSU not ready, Thread 0 ****/
		test("Test_19", 0);
		set_vaddr_vlen(0, 0, 38'h200000000, 20'h10);
		set_vaddr_vlen(0, 1, 38'h200200000, 20'h10);
		rrq_ready(1'b0);
		trig_latch(16'b00_00_00_00_00_00_00_11);
		wait_pos_clk(32);
		rrq_ready(1'b1);
		wait_pos_clk(32);
		test("Done_19", 4);

		/* Initial config */
		rrq_ready(1'b1);
`endif



`ifdef TESTS_WE_NOT_RDY
		/*** Test 1A - WE not ready, one vector, thread 0, arg Rs ****/
		test("Test_1A", 0);
		set_vaddr_vlen(0, 0, 38'h200000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_00_00_00_01);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_00_00_00_01);
		wait_pos_clk(32);
		test("Done_1A", 4);


		/*** Test 1B - WE not ready, one vector, thread 0, arg Rt ****/
		test("Test_1B", 0);
		set_vaddr_vlen(0, 1, 38'h200200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_00_00_00_10);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_00_00_00_10);
		wait_pos_clk(32);
		test("Done_1B", 4);


		/*** Test 1C - WE not ready, one vector, thread 1, arg Rs ****/
		test("Test_1C", 0);
		set_vaddr_vlen(1, 0, 38'h202000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_00_00_01_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_00_00_01_00);
		wait_pos_clk(32);
		test("Done_1C", 4);


		/*** Test 1D - WE not ready, one vector, thread 1, arg Rt ****/
		test("Test_1D", 0);
		set_vaddr_vlen(1, 1, 38'h202200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_00_00_10_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_00_00_10_00);
		wait_pos_clk(32);
		test("Done_1D", 4);


		/*** Test 1E - WE not ready, one vector, thread 2, arg Rs ****/
		test("Test_1E", 0);
		set_vaddr_vlen(2, 0, 38'h204000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_00_01_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_00_01_00_00);
		wait_pos_clk(32);
		test("Done_1E", 4);


		/*** Test 1F - WE not ready, one vector, thread 2, arg Rt ****/
		test("Test_1F", 0);
		set_vaddr_vlen(2, 1, 38'h204200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_00_10_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_00_10_00_00);
		wait_pos_clk(32);
		test("Done_1F", 4);


		/*** Test 20 - WE not ready, one vector, thread 3, arg Rs ****/
		test("Test_20", 0);
		set_vaddr_vlen(3, 0, 38'h206000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_01_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_01_00_00_00);
		wait_pos_clk(32);
		test("Done_20", 4);


		/*** Test 21 - WE not ready, one vector, thread 3, arg Rt ****/
		test("Test_21", 0);
		set_vaddr_vlen(3, 1, 38'h206200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_00_10_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_00_10_00_00_00);
		wait_pos_clk(32);
		test("Done_21", 4);


		/*** Test 22 - WE not ready, one vector, thread 4, arg Rs ****/
		test("Test_22", 0);
		set_vaddr_vlen(4, 0, 38'h208000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_01_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_01_00_00_00_00);
		wait_pos_clk(32);
		test("Done_22", 4);


		/*** Test 23 - WE not ready, one vector, thread 4, arg Rt ****/
		test("Test_23", 0);
		set_vaddr_vlen(4, 1, 38'h208200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_00_10_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_00_10_00_00_00_00);
		wait_pos_clk(32);
		test("Done_23", 4);


		/*** Test 24 - WE not ready, one vector, thread 5, arg Rs ****/
		test("Test_24", 0);
		set_vaddr_vlen(5, 0, 38'h20A000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_01_00_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_01_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_24", 4);


		/*** Test 25 - WE not ready, one vector, thread 5, arg Rt ****/
		test("Test_25", 0);
		set_vaddr_vlen(5, 1, 38'h20A200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_00_10_00_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_00_10_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_25", 4);


		/*** Test 26 - WE not ready, one vector, thread 6, arg Rs ****/
		test("Test_26", 0);
		set_vaddr_vlen(6, 0, 38'h20C000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_01_00_00_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_01_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_26", 4);


		/*** Test 27 - WE not ready, one vector, thread 6, arg Rt ****/
		test("Test_27", 0);
		set_vaddr_vlen(6, 1, 38'h20C200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b00_10_00_00_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b00_10_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_27", 4);


		/*** Test 28 - WE not ready, one vector, thread 7, arg Rs ****/
		test("Test_28", 0);
		set_vaddr_vlen(7, 0, 38'h20E000000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b01_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b01_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_28", 4);


		/*** Test 29 - WE not ready, one vector, thread 7, arg Rt ****/
		test("Test_29", 0);
		set_vaddr_vlen(7, 1, 38'h20E200000, 20'h10);
		we_ready(16'b00_00_00_00_00_00_00_00);
		trig_latch(16'b10_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		we_ready(16'b10_00_00_00_00_00_00_00);
		wait_pos_clk(32);
		test("Done_29", 4);

		/* Initial config */
		we_ready(16'hffff);
`endif



`ifdef TESTS_ERR_FLUSH
		/*** Test 2A - Error flush, all threads ****/
		test("Test_2A", 0);
		set_vaddr_vlen(0, 0, 38'h200000000, 20'h100);
		set_vaddr_vlen(0, 1, 38'h200200000, 20'h100);
		set_vaddr_vlen(1, 0, 38'h202000000, 20'h100);
		set_vaddr_vlen(1, 1, 38'h202200000, 20'h100);
		set_vaddr_vlen(2, 0, 38'h204000000, 20'h100);
		set_vaddr_vlen(2, 1, 38'h204200000, 20'h100);
		set_vaddr_vlen(3, 0, 38'h206000000, 20'h100);
		set_vaddr_vlen(3, 1, 38'h206200000, 20'h100);
		set_vaddr_vlen(4, 0, 38'h208000000, 20'h100);
		set_vaddr_vlen(4, 1, 38'h208200000, 20'h100);
		set_vaddr_vlen(5, 0, 38'h20A000000, 20'h100);
		set_vaddr_vlen(5, 1, 38'h20A200000, 20'h100);
		set_vaddr_vlen(6, 0, 38'h20C000000, 20'h100);
		set_vaddr_vlen(6, 1, 38'h20C200000, 20'h100);
		set_vaddr_vlen(7, 0, 38'h20E000000, 20'h100);
		set_vaddr_vlen(7, 1, 38'h20E200000, 20'h100);
		trig_latch(16'b11_11_11_11_11_11_11_11);
		wait_pos_clk(16);
		@(posedge clk) err_flush <= 1'b1;
		@(posedge clk) err_flush <= 1'b0;
		wait_pos_clk(160);
		test("Done_2A", 4);
`endif



		#500 $finish;
	end



	/* Requests dispatcher unit */
	vxe_vpu_prod_eu_rq_disp #(
		.IN_DEPTH_POW2(2),
		.OUT_DEPTH_POW2(2)
	) rq_disp (
		.clk(clk),
		.nrst(nrst),
		.i_err_flush(err_flush),
		.o_busy(busy),
		.i_rs0_valid(rs0_valid),
		.i_rs0_addr(rs0_addr),
		.i_rs0_we_mask(rs0_we_mask),
		.o_rs0_incr(rs0_incr),
		.i_rt0_valid(rt0_valid),
		.i_rt0_addr(rt0_addr),
		.i_rt0_we_mask(rt0_we_mask),
		.o_rt0_incr(rt0_incr),
		.i_rs1_valid(rs1_valid),
		.i_rs1_addr(rs1_addr),
		.i_rs1_we_mask(rs1_we_mask),
		.o_rs1_incr(rs1_incr),
		.i_rt1_valid(rt1_valid),
		.i_rt1_addr(rt1_addr),
		.i_rt1_we_mask(rt1_we_mask),
		.o_rt1_incr(rt1_incr),
		.i_rs2_valid(rs2_valid),
		.i_rs2_addr(rs2_addr),
		.i_rs2_we_mask(rs2_we_mask),
		.o_rs2_incr(rs2_incr),
		.i_rt2_valid(rt2_valid),
		.i_rt2_addr(rt2_addr),
		.i_rt2_we_mask(rt2_we_mask),
		.o_rt2_incr(rt2_incr),
		.i_rs3_valid(rs3_valid),
		.i_rs3_addr(rs3_addr),
		.i_rs3_we_mask(rs3_we_mask),
		.o_rs3_incr(rs3_incr),
		.i_rt3_valid(rt3_valid),
		.i_rt3_addr(rt3_addr),
		.i_rt3_we_mask(rt3_we_mask),
		.o_rt3_incr(rt3_incr),
		.i_rs4_valid(rs4_valid),
		.i_rs4_addr(rs4_addr),
		.i_rs4_we_mask(rs4_we_mask),
		.o_rs4_incr(rs4_incr),
		.i_rt4_valid(rt4_valid),
		.i_rt4_addr(rt4_addr),
		.i_rt4_we_mask(rt4_we_mask),
		.o_rt4_incr(rt4_incr),
		.i_rs5_valid(rs5_valid),
		.i_rs5_addr(rs5_addr),
		.i_rs5_we_mask(rs5_we_mask),
		.o_rs5_incr(rs5_incr),
		.i_rt5_valid(rt5_valid),
		.i_rt5_addr(rt5_addr),
		.i_rt5_we_mask(rt5_we_mask),
		.o_rt5_incr(rt5_incr),
		.i_rs6_valid(rs6_valid),
		.i_rs6_addr(rs6_addr),
		.i_rs6_we_mask(rs6_we_mask),
		.o_rs6_incr(rs6_incr),
		.i_rt6_valid(rt6_valid),
		.i_rt6_addr(rt6_addr),
		.i_rt6_we_mask(rt6_we_mask),
		.o_rt6_incr(rt6_incr),
		.i_rs7_valid(rs7_valid),
		.i_rs7_addr(rs7_addr),
		.i_rs7_we_mask(rs7_we_mask),
		.o_rs7_incr(rs7_incr),
		.i_rt7_valid(rt7_valid),
		.i_rt7_addr(rt7_addr),
		.i_rt7_we_mask(rt7_we_mask),
		.o_rt7_incr(rt7_incr),
		.o_rrq_rs0_we_mask(rrq_rs0_we_mask),
		.o_rrq_rs0_we_wr(rrq_rs0_we_wr),
		.i_rrq_rs0_we_rdy(rrq_rs0_we_rdy),
		.o_rrq_rt0_we_mask(rrq_rt0_we_mask),
		.o_rrq_rt0_we_wr(rrq_rt0_we_wr),
		.i_rrq_rt0_we_rdy(rrq_rt0_we_rdy),
		.o_rrq_rs1_we_mask(rrq_rs1_we_mask),
		.o_rrq_rs1_we_wr(rrq_rs1_we_wr),
		.i_rrq_rs1_we_rdy(rrq_rs1_we_rdy),
		.o_rrq_rt1_we_mask(rrq_rt1_we_mask),
		.o_rrq_rt1_we_wr(rrq_rt1_we_wr),
		.i_rrq_rt1_we_rdy(rrq_rt1_we_rdy),
		.o_rrq_rs2_we_mask(rrq_rs2_we_mask),
		.o_rrq_rs2_we_wr(rrq_rs2_we_wr),
		.i_rrq_rs2_we_rdy(rrq_rs2_we_rdy),
		.o_rrq_rt2_we_mask(rrq_rt2_we_mask),
		.o_rrq_rt2_we_wr(rrq_rt2_we_wr),
		.i_rrq_rt2_we_rdy(rrq_rt2_we_rdy),
		.o_rrq_rs3_we_mask(rrq_rs3_we_mask),
		.o_rrq_rs3_we_wr(rrq_rs3_we_wr),
		.i_rrq_rs3_we_rdy(rrq_rs3_we_rdy),
		.o_rrq_rt3_we_mask(rrq_rt3_we_mask),
		.o_rrq_rt3_we_wr(rrq_rt3_we_wr),
		.i_rrq_rt3_we_rdy(rrq_rt3_we_rdy),
		.o_rrq_rs4_we_mask(rrq_rs4_we_mask),
		.o_rrq_rs4_we_wr(rrq_rs4_we_wr),
		.i_rrq_rs4_we_rdy(rrq_rs4_we_rdy),
		.o_rrq_rt4_we_mask(rrq_rt4_we_mask),
		.o_rrq_rt4_we_wr(rrq_rt4_we_wr),
		.i_rrq_rt4_we_rdy(rrq_rt4_we_rdy),
		.o_rrq_rs5_we_mask(rrq_rs5_we_mask),
		.o_rrq_rs5_we_wr(rrq_rs5_we_wr),
		.i_rrq_rs5_we_rdy(rrq_rs5_we_rdy),
		.o_rrq_rt5_we_mask(rrq_rt5_we_mask),
		.o_rrq_rt5_we_wr(rrq_rt5_we_wr),
		.i_rrq_rt5_we_rdy(rrq_rt5_we_rdy),
		.o_rrq_rs6_we_mask(rrq_rs6_we_mask),
		.o_rrq_rs6_we_wr(rrq_rs6_we_wr),
		.i_rrq_rs6_we_rdy(rrq_rs6_we_rdy),
		.o_rrq_rt6_we_mask(rrq_rt6_we_mask),
		.o_rrq_rt6_we_wr(rrq_rt6_we_wr),
		.i_rrq_rt6_we_rdy(rrq_rt6_we_rdy),
		.o_rrq_rs7_we_mask(rrq_rs7_we_mask),
		.o_rrq_rs7_we_wr(rrq_rs7_we_wr),
		.i_rrq_rs7_we_rdy(rrq_rs7_we_rdy),
		.o_rrq_rt7_we_mask(rrq_rt7_we_mask),
		.o_rrq_rt7_we_wr(rrq_rt7_we_wr),
		.i_rrq_rt7_we_rdy(rrq_rt7_we_rdy),
		.i_rrq_rdy(rrq_rdy),
		.o_rrq_wr(rrq_wr),
		.o_rrq_th(rrq_th),
		.o_rrq_addr(rrq_addr),
		.o_rrq_arg(rrq_arg)
	);


	/* Create address generator instances */
	genvar i, j;
	generate
	for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
	begin : t
		for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
		begin : r
			wire		incr;
			wire		valid;
			wire [36:0]	addr;
			wire [1:0]	we_mask;

			vxe_vpu_prod_eu_agen agen(
				.clk(clk),
				.nrst(nrst),
				.i_vaddr(ag_vaddr[2*i + j]),
				.i_vlen(ag_vlen[2*i + j]),
				.i_latch(ag_latch[2*i + j]),
				.i_incr(incr),
				.o_valid(valid),
				.o_addr(addr),
				.o_we_mask(we_mask)
			);
		end
	end
	endgenerate

	/* Connect generated blocks */
	assign rs0_valid = t[0].r[0].valid;
	assign rs0_addr = t[0].r[0].addr;
	assign rs0_we_mask = t[0].r[0].we_mask;
	assign t[0].r[0].incr = rs0_incr;
	assign rt0_valid = t[0].r[1].valid;
	assign rt0_addr = t[0].r[1].addr;
	assign rt0_we_mask = t[0].r[1].we_mask;
	assign t[0].r[1].incr = rt0_incr;
	assign rs1_valid = t[1].r[0].valid;
	assign rs1_addr = t[1].r[0].addr;
	assign rs1_we_mask = t[1].r[0].we_mask;
	assign t[1].r[0].incr = rs1_incr;
	assign rt1_valid = t[1].r[1].valid;
	assign rt1_addr = t[1].r[1].addr;
	assign rt1_we_mask = t[1].r[1].we_mask;
	assign t[1].r[1].incr = rt1_incr;
	assign rs2_valid = t[2].r[0].valid;
	assign rs2_addr = t[2].r[0].addr;
	assign rs2_we_mask = t[2].r[0].we_mask;
	assign t[2].r[0].incr = rs2_incr;
	assign rt2_valid = t[2].r[1].valid;
	assign rt2_addr = t[2].r[1].addr;
	assign rt2_we_mask = t[2].r[1].we_mask;
	assign t[2].r[1].incr = rt2_incr;
	assign rs3_valid = t[3].r[0].valid;
	assign rs3_addr = t[3].r[0].addr;
	assign rs3_we_mask = t[3].r[0].we_mask;
	assign t[3].r[0].incr = rs3_incr;
	assign rt3_valid = t[3].r[1].valid;
	assign rt3_addr = t[3].r[1].addr;
	assign rt3_we_mask = t[3].r[1].we_mask;
	assign t[3].r[1].incr = rt3_incr;
	assign rs4_valid = t[4].r[0].valid;
	assign rs4_addr = t[4].r[0].addr;
	assign rs4_we_mask = t[4].r[0].we_mask;
	assign t[4].r[0].incr = rs4_incr;
	assign rt4_valid = t[4].r[1].valid;
	assign rt4_addr = t[4].r[1].addr;
	assign rt4_we_mask = t[4].r[1].we_mask;
	assign t[4].r[1].incr = rt4_incr;
	assign rs5_valid = t[5].r[0].valid;
	assign rs5_addr = t[5].r[0].addr;
	assign rs5_we_mask = t[5].r[0].we_mask;
	assign t[5].r[0].incr = rs5_incr;
	assign rt5_valid = t[5].r[1].valid;
	assign rt5_addr = t[5].r[1].addr;
	assign rt5_we_mask = t[5].r[1].we_mask;
	assign t[5].r[1].incr = rt5_incr;
	assign rs6_valid = t[6].r[0].valid;
	assign rs6_addr = t[6].r[0].addr;
	assign rs6_we_mask = t[6].r[0].we_mask;
	assign t[6].r[0].incr = rs6_incr;
	assign rt6_valid = t[6].r[1].valid;
	assign rt6_addr = t[6].r[1].addr;
	assign rt6_we_mask = t[6].r[1].we_mask;
	assign t[6].r[1].incr = rt6_incr;
	assign rs7_valid = t[7].r[0].valid;
	assign rs7_addr = t[7].r[0].addr;
	assign rs7_we_mask = t[7].r[0].we_mask;
	assign t[7].r[0].incr = rs7_incr;
	assign rt7_valid = t[7].r[1].valid;
	assign rt7_addr = t[7].r[1].addr;
	assign rt7_we_mask = t[7].r[1].we_mask;
	assign t[7].r[1].incr = rt7_incr;


	/* Connect FIFO ready signals */
	assign rrq_rs0_we_rdy = rrq_we_rdy[0];
	assign rrq_rt0_we_rdy = rrq_we_rdy[1];
	assign rrq_rs1_we_rdy = rrq_we_rdy[2];
	assign rrq_rt1_we_rdy = rrq_we_rdy[3];
	assign rrq_rs2_we_rdy = rrq_we_rdy[4];
	assign rrq_rt2_we_rdy = rrq_we_rdy[5];
	assign rrq_rs3_we_rdy = rrq_we_rdy[6];
	assign rrq_rt3_we_rdy = rrq_we_rdy[7];
	assign rrq_rs4_we_rdy = rrq_we_rdy[8];
	assign rrq_rt4_we_rdy = rrq_we_rdy[9];
	assign rrq_rs5_we_rdy = rrq_we_rdy[10];
	assign rrq_rt5_we_rdy = rrq_we_rdy[11];
	assign rrq_rs6_we_rdy = rrq_we_rdy[12];
	assign rrq_rt6_we_rdy = rrq_we_rdy[13];
	assign rrq_rs7_we_rdy = rrq_we_rdy[14];
	assign rrq_rt7_we_rdy = rrq_we_rdy[15];


endmodule /* tb_vxe_vpu_prod_eu_rq_disp */
