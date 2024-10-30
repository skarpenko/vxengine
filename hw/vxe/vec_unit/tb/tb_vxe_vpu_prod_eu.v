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
 * Testbench for VxE VPU product execution unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


/* Test groups */
`define TESTS_ONE_THREAD	/* One thread is enabled */
`define TESTS_ALL_THREADS	/* All threads are enabled */
`define TESTS_LSU_ERROR		/* Load-store error */


module tb_vxe_vpu_prod_eu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Control unit interface */
	reg		start;
	wire		busy;
	/* LSU interface */
	reg		lsu_err;
	wire		lsu_rrq_rdy;
	wire		lsu_rrq_wr;
	wire [2:0]	lsu_rrq_th;
	wire [36:0]	lsu_rrq_addr;
	wire		lsu_rrq_arg;
	wire		lsu_rrs_vld;
	wire		lsu_rrs_rd;
	wire [2:0]	lsu_rrs_th;
	wire		lsu_rrs_arg;
	wire [63:0]	lsu_rrs_data;
	/* Register file interface */
	wire [2:0]	prod_th;
	wire [2:0]	prod_ridx;
	wire		prod_wr_en;
	wire [37:0]	prod_data;
	/* Register values */
	reg [31:0]	th0_acc;
	reg [19:0]	th0_vl;
	reg		th0_en;
	reg [37:0]	th0_rs;
	reg [37:0]	th0_rt;
	reg [31:0]	th1_acc;
	reg [19:0]	th1_vl;
	reg		th1_en;
	reg [37:0]	th1_rs;
	reg [37:0]	th1_rt;
	reg [31:0]	th2_acc;
	reg [19:0]	th2_vl;
	reg		th2_en;
	reg [37:0]	th2_rs;
	reg [37:0]	th2_rt;
	reg [31:0]	th3_acc;
	reg [19:0]	th3_vl;
	reg		th3_en;
	reg [37:0]	th3_rs;
	reg [37:0]	th3_rt;
	reg [31:0]	th4_acc;
	reg [19:0]	th4_vl;
	reg		th4_en;
	reg [37:0]	th4_rs;
	reg [37:0]	th4_rt;
	reg [31:0]	th5_acc;
	reg [19:0]	th5_vl;
	reg		th5_en;
	reg [37:0]	th5_rs;
	reg [37:0]	th5_rt;
	reg [31:0]	th6_acc;
	reg [19:0]	th6_vl;
	reg		th6_en;
	reg [37:0]	th6_rs;
	reg [37:0]	th6_rt;
	reg [31:0]	th7_acc;
	reg [19:0]	th7_vl;
	reg		th7_en;
	reg [37:0]	th7_rs;
	reg [37:0]	th7_rt;

	/** Testbench specific **/
	reg [0:55]	test_name;		/* Test name, for ex.: Test_01 */


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


	/* Set threads */
	task set_threads;
	input [7:0]	mask;	/* Thread mask */
	input [31:0]	acc;	/* Accumulator value */
	input [19:0]	vl;	/* Vector length */
	input [37:0]	rs;	/* Rs addr */
	input [37:0]	rt;	/* Rt addr */
	begin
		@(posedge clk)
		begin
			if(mask[0])
			begin
				th0_acc <= acc;
				th0_vl <= vl;
				th0_rs <= rs;
				th0_rt <= rt;
			end
			if(mask[1])
			begin
				th1_acc <= acc;
				th1_vl <= vl;
				th1_rs <= rs;
				th1_rt <= rt;
			end
			if(mask[2])
			begin
				th2_acc <= acc;
				th2_vl <= vl;
				th2_rs <= rs;
				th2_rt <= rt;
			end
			if(mask[3])
			begin
				th3_acc <= acc;
				th3_vl <= vl;
				th3_rs <= rs;
				th3_rt <= rt;
			end
			if(mask[4])
			begin
				th4_acc <= acc;
				th4_vl <= vl;
				th4_rs <= rs;
				th4_rt <= rt;
			end
			if(mask[5])
			begin
				th5_acc <= acc;
				th5_vl <= vl;
				th5_rs <= rs;
				th5_rt <= rt;
			end
			if(mask[6])
			begin
				th6_acc <= acc;
				th6_vl <= vl;
				th6_rs <= rs;
				th6_rt <= rt;
			end
			if(mask[7])
			begin
				th7_acc <= acc;
				th7_vl <= vl;
				th7_rs <= rs;
				th7_rt <= rt;
			end
		end
	end
	endtask


	/* Set thread enables */
	task set_threads_en;
	input [7:0]	mask;	/* Thread mask */
	begin
		@(posedge clk)
		begin
			th0_en <= mask[0];
			th1_en <= mask[1];
			th2_en <= mask[2];
			th3_en <= mask[3];
			th4_en <= mask[4];
			th5_en <= mask[5];
			th6_en <= mask[6];
			th7_en <= mask[7];
		end
	end
	endtask


	/* Set start */
	task set_start;
	begin
		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;
	end
	endtask


	/* Set error */
	task set_error;
	begin
		@(posedge clk) lsu_err <= 1'b1;
		@(posedge clk) lsu_err <= 1'b0;
	end
	endtask



	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_prod_eu);

		clk = 1'b1;
		nrst = 1'b0;

		start = 1'b0;
		lsu_err = 1'b0;
		th0_en = 1'b0;
		th1_en = 1'b0;
		th2_en = 1'b0;
		th3_en = 1'b0;
		th4_en = 1'b0;
		th5_en = 1'b0;
		th6_en = 1'b0;
		th7_en = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(1);
		/***********************************************************/

		/* Set threads input */
		test("SetThrs", 0);
		set_threads(8'b0000_0001, 32'h4000_0000, 20'h04, 38'h0_0000, 38'h0_1000);
		set_threads(8'b0000_0010, 32'h4000_1000, 20'h04, 38'h1_0000, 38'h1_1000);
		set_threads(8'b0000_0100, 32'h4000_2000, 20'h04, 38'h2_0000, 38'h2_1000);
		set_threads(8'b0000_1000, 32'h4000_3000, 20'h04, 38'h3_0000, 38'h3_1000);
		set_threads(8'b0001_0000, 32'h4000_4000, 20'h04, 38'h4_0000, 38'h4_1000);
		set_threads(8'b0010_0000, 32'h4000_5000, 20'h04, 38'h5_0000, 38'h5_1000);
		set_threads(8'b0100_0000, 32'h4000_6000, 20'h04, 38'h6_0000, 38'h6_1000);
		set_threads(8'b1000_0000, 32'h4000_7000, 20'h04, 38'h7_0000, 38'h7_1000);
		wait_pos_clk(4);
		test("Done   ", 4);


`ifdef TESTS_ONE_THREAD
		/*** Test 00 - Thread 0 ***/
		test("Test_00", 0);
		set_threads_en(8'b0000_0001);
		set_start();
		wait_pos_clk(48);
		test("Done_00", 4);


		/*** Test 01 - Thread 1 ***/
		test("Test_01", 0);
		set_threads_en(8'b0000_0010);
		set_start();
		wait_pos_clk(48 + 4*1);	/* Need more time to complete */
		test("Done_01", 4);


		/*** Test 02 - Thread 2 ***/
		test("Test_02", 0);
		set_threads_en(8'b0000_0100);
		set_start();
		wait_pos_clk(48 + 4*2);	/* Need more time to complete */
		test("Done_02", 4);


		/*** Test 03 - Thread 3 ***/
		test("Test_03", 0);
		set_threads_en(8'b0000_1000);
		set_start();
		wait_pos_clk(48 + 4*3);	/* Need more time to complete */
		test("Done_03", 4);


		/*** Test 04 - Thread 4 ***/
		test("Test_04", 0);
		set_threads_en(8'b0001_0000);
		set_start();
		wait_pos_clk(48 + 4*4);	/* Need more time to complete */
		test("Done_04", 4);


		/*** Test 05 - Thread 5 ***/
		test("Test_05", 0);
		set_threads_en(8'b0010_0000);
		set_start();
		wait_pos_clk(48 + 4*5);	/* Need more time to complete */
		test("Done_05", 4);


		/*** Test 06 - Thread 6 ***/
		test("Test_06", 0);
		set_threads_en(8'b0100_0000);
		set_start();
		wait_pos_clk(48 + 4*6);	/* Need more time to complete */
		test("Done_06", 4);


		/*** Test 07 - Thread 7 ***/
		test("Test_07", 0);
		set_threads_en(8'b1000_0000);
		set_start();
		wait_pos_clk(48 + 4*7);	/* Need more time to complete */
		test("Done_07", 4);
`endif


`ifdef TESTS_ALL_THREADS
		/*** Test 08 - All threads ***/
		test("Test_08", 0);
		set_threads_en(8'b1111_1111);
		set_start();
		wait_pos_clk(64);
		test("Done_08", 4);
`endif


`ifdef TESTS_LSU_ERROR
		/* Increase threads length */
		set_threads(8'b0000_0001, 32'h4000_0000, 20'h100, 38'h0_0000, 38'h0_1000);
		set_threads(8'b0000_0010, 32'h4000_1000, 20'h100, 38'h1_0000, 38'h1_1000);
		set_threads(8'b0000_0100, 32'h4000_2000, 20'h100, 38'h2_0000, 38'h2_1000);
		set_threads(8'b0000_1000, 32'h4000_3000, 20'h100, 38'h3_0000, 38'h3_1000);
		set_threads(8'b0001_0000, 32'h4000_4000, 20'h100, 38'h4_0000, 38'h4_1000);
		set_threads(8'b0010_0000, 32'h4000_5000, 20'h100, 38'h5_0000, 38'h5_1000);
		set_threads(8'b0100_0000, 32'h4000_6000, 20'h100, 38'h6_0000, 38'h6_1000);
		set_threads(8'b1000_0000, 32'h4000_7000, 20'h100, 38'h7_0000, 38'h7_1000);
		wait_pos_clk(4);

		/*** Test 09 - LSU error ***/
		test("Test_09", 0);
		set_threads_en(8'b1111_1111);
		set_start();
		wait_pos_clk(16);
		set_error();
		wait_pos_clk(128);
		test("Done_09", 4);
`endif


		#500 $finish;
	end



	/* Product execution unit instance */
	vxe_vpu_prod_eu #(
		.WE_DEPTH_POW2(2),
		.OP_DEPTH_POW2(2),
		/* Requests dispatcher unit */
		.RQD_IN_DEPTH_POW2(2),
		.RQD_OUT_DEPTH_POW2(2),
		/* Responses distributor unit */
		.RSD_IN_WE_DEPTH_POW2(2),
		.RSD_IN_RS_DEPTH_POW2(3),
		.RSD_OUT_OP_DEPTH_POW2(2),
		/* FMAC scheduler unit */
		.FMAC_IN_OP_DEPTH_POW2(2)
	) prod_eu (
		/* Global signals */
		.clk(clk),
		.nrst(nrst),
		/* Control unit interface */
		.i_start(start),
		.o_busy(busy),
		/* LSU interface */
		.i_lsu_err(lsu_err),
		.i_lsu_rrq_rdy(lsu_rrq_rdy),
		.o_lsu_rrq_wr(lsu_rrq_wr),
		.o_lsu_rrq_th(lsu_rrq_th),
		.o_lsu_rrq_addr(lsu_rrq_addr),
		.o_lsu_rrq_arg(lsu_rrq_arg),
		.i_lsu_rrs_vld(lsu_rrs_vld),
		.o_lsu_rrs_rd(lsu_rrs_rd),
		.i_lsu_rrs_th(lsu_rrs_th),
		.i_lsu_rrs_arg(lsu_rrs_arg),
		.i_lsu_rrs_data(lsu_rrs_data),
		/* Register file interface */
		.o_prod_th(prod_th),
		.o_prod_ridx(prod_ridx),
		.o_prod_wr_en(prod_wr_en),
		.o_prod_data(prod_data),
		/* Register values */
		.i_th0_acc(th0_acc),
		.i_th0_vl(th0_vl),
		.i_th0_en(th0_en),
		.i_th0_rs(th0_rs),
		.i_th0_rt(th0_rt),
		.i_th1_acc(th1_acc),
		.i_th1_vl(th1_vl),
		.i_th1_en(th1_en),
		.i_th1_rs(th1_rs),
		.i_th1_rt(th1_rt),
		.i_th2_acc(th2_acc),
		.i_th2_vl(th2_vl),
		.i_th2_en(th2_en),
		.i_th2_rs(th2_rs),
		.i_th2_rt(th2_rt),
		.i_th3_acc(th3_acc),
		.i_th3_vl(th3_vl),
		.i_th3_en(th3_en),
		.i_th3_rs(th3_rs),
		.i_th3_rt(th3_rt),
		.i_th4_acc(th4_acc),
		.i_th4_vl(th4_vl),
		.i_th4_en(th4_en),
		.i_th4_rs(th4_rs),
		.i_th4_rt(th4_rt),
		.i_th5_acc(th5_acc),
		.i_th5_vl(th5_vl),
		.i_th5_en(th5_en),
		.i_th5_rs(th5_rs),
		.i_th5_rt(th5_rt),
		.i_th6_acc(th6_acc),
		.i_th6_vl(th6_vl),
		.i_th6_en(th6_en),
		.i_th6_rs(th6_rs),
		.i_th6_rt(th6_rt),
		.i_th7_acc(th7_acc),
		.i_th7_vl(th7_vl),
		.i_th7_en(th7_en),
		.i_th7_rs(th7_rs),
		.i_th7_rt(th7_rt)
	);



/******************** Requests handling simulation logic **********************/


localparam FIFO_DEPTH_POW2 = 3;


/*** Requests FIFO ***/
reg [2:0]		rq_fifo_th[0:2**FIFO_DEPTH_POW2-1];	/* Thread */
reg [36:0]		rq_fifo_addr[0:2**FIFO_DEPTH_POW2-1];	/* Address (ignored) */
reg			rq_fifo_arg[0:2**FIFO_DEPTH_POW2-1];	/* Argument */
reg [FIFO_DEPTH_POW2:0]	rq_fifo_rp;	/* Read pointer */
reg [FIFO_DEPTH_POW2:0]	rq_fifo_wp;	/* Write pointer */

/* Previous FIFO read pointer */
wire [FIFO_DEPTH_POW2:0]	rq_fifo_pre_rp = rq_fifo_rp - 1'b1;

/* FIFO states */
wire rq_fifo_empty = (rq_fifo_rp[FIFO_DEPTH_POW2] == rq_fifo_wp[FIFO_DEPTH_POW2]) &&
	(rq_fifo_rp[FIFO_DEPTH_POW2-1:0] == rq_fifo_wp[FIFO_DEPTH_POW2-1:0]);
wire rq_fifo_full = (rq_fifo_rp[FIFO_DEPTH_POW2] != rq_fifo_wp[FIFO_DEPTH_POW2]) &&
	(rq_fifo_rp[FIFO_DEPTH_POW2-1:0] == rq_fifo_wp[FIFO_DEPTH_POW2-1:0]);
wire rq_fifo_pre_full = (rq_fifo_pre_rp[FIFO_DEPTH_POW2] != rq_fifo_wp[FIFO_DEPTH_POW2]) &&
	(rq_fifo_pre_rp[FIFO_DEPTH_POW2-1:0] == rq_fifo_wp[FIFO_DEPTH_POW2-1:0]);

/* FIFO stall */
wire rq_fifo_stall = rq_fifo_full || rq_fifo_pre_full;

/* Response data */
reg [31:0]	fdata1;
reg [31:0]	fdata2;

/* LSU wires */
assign lsu_rrq_rdy = !rq_fifo_stall;
assign lsu_rrs_vld = !rq_fifo_empty;
assign lsu_rrs_th = rq_fifo_th[rq_fifo_rp[FIFO_DEPTH_POW2-1:0]];
assign lsu_rrs_arg = rq_fifo_arg[rq_fifo_rp[FIFO_DEPTH_POW2-1:0]];
assign lsu_rrs_data = { fdata2, fdata1 };


/* Requests receive logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rq_fifo_wp <= {(FIFO_DEPTH_POW2+1){1'b0}};
	end
	else if(lsu_rrq_wr && !rq_fifo_stall)
	begin
		rq_fifo_th[rq_fifo_wp[FIFO_DEPTH_POW2-1:0]] <= lsu_rrq_th;
		rq_fifo_addr[rq_fifo_wp[FIFO_DEPTH_POW2-1:0]] <= lsu_rrq_addr;
		rq_fifo_arg[rq_fifo_wp[FIFO_DEPTH_POW2-1:0]] <= lsu_rrq_arg;
		rq_fifo_wp <= rq_fifo_wp + 1'b1;
	end
end


/* Response logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fdata1 <= 32'h0010_0000;
		fdata2 <= 32'h0020_0000;
		rq_fifo_rp <= {(FIFO_DEPTH_POW2+1){1'b0}};
	end
	else if(lsu_rrs_rd && !rq_fifo_empty)
	begin
		rq_fifo_rp <= rq_fifo_rp + 1'b1;
		fdata1 <= fdata1 + 1'b1;
		fdata2 <= fdata2 + 1'b1;
	end
end


endmodule /* tb_vxe_vpu_prod_eu */
