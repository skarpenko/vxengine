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
 * Testbench for VxE VPU activation function execution unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_actf_eu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Control unit interface */
	reg		start;
	wire		busy;
	reg		leaky;
	reg [6:0]	expd;
	/* Register file interface */
	wire [2:0]	th;
	wire [2:0]	ridx;
	wire		wr_en;
	wire [37:0]	data;
	/* Register values */
	reg [31:0]	th0_acc;
	reg		th0_en;
	reg [31:0]	th1_acc;
	reg		th1_en;
	reg [31:0]	th2_acc;
	reg		th2_en;
	reg [31:0]	th3_acc;
	reg		th3_en;
	reg [31:0]	th4_acc;
	reg		th4_en;
	reg [31:0]	th5_acc;
	reg		th5_en;
	reg [31:0]	th6_acc;
	reg		th6_en;
	reg [31:0]	th7_acc;
	reg		th7_en;


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
		$dumpvars(0, tb_vxe_vpu_actf_eu);

		clk = 1'b1;
		nrst = 1'b0;
		start = 1'b0;
		leaky = 1'b0;
		th0_en = 1'b0;
		th1_en = 1'b0;
		th2_en = 1'b0;
		th3_en = 1'b0;
		th4_en = 1'b0;
		th5_en = 1'b0;
		th6_en = 1'b0;
		th7_en = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk();
		/***********************************************************/


		/*** Thread 0 is enabled  ***/
		@(posedge clk)
		begin
			th0_en <= 1'b1;
			th0_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk) th0_en <= 1'b0;

		wait_pos_clk4();


		/*** Thread 1 is enabled  ***/
		@(posedge clk)
		begin
			th1_en <= 1'b1;
			th1_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk) th1_en <= 1'b0;

		wait_pos_clk4();


		/*** Thread 2 is enabled  ***/
		@(posedge clk)
		begin
			th2_en <= 1'b1;
			th2_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk8();

		@(posedge clk) th2_en <= 1'b0;

		wait_pos_clk4();


		/*** Thread 3 is enabled  ***/
		@(posedge clk)
		begin
			th3_en <= 1'b1;
			th3_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk) th3_en <= 1'b0;

		wait_pos_clk4();


		/*** Thread 4 is enabled  ***/
		@(posedge clk)
		begin
			th4_en <= 1'b1;
			th4_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk) th4_en <= 1'b0;

		wait_pos_clk4();


		/*** Thread 5 is enabled  ***/
		@(posedge clk)
		begin
			th5_en <= 1'b1;
			th5_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk) th5_en <= 1'b0;

		wait_pos_clk4();


		/*** Thread 6 is enabled  ***/
		@(posedge clk)
		begin
			th6_en <= 1'b1;
			th6_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk) th6_en <= 1'b0;

		wait_pos_clk4();


		/*** Thread 7 is enabled  ***/
		@(posedge clk)
		begin
			th7_en <= 1'b1;
			th7_acc <= 32'b0;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk) th7_en <= 1'b0;

		wait_pos_clk4();


		/*** All threads are enabled  ***/
		@(posedge clk)
		begin
			th0_en <= 1'b1;
			th0_acc <= 32'h7f800000;
			th1_en <= 1'b1;
			th1_acc <= 32'h7f800000;
			th2_en <= 1'b1;
			th2_acc <= 32'h7f800000;
			th3_en <= 1'b1;
			th3_acc <= 32'h7f800000;
			th4_en <= 1'b1;
			th4_acc <= 32'h7f800000;
			th5_en <= 1'b1;
			th5_acc <= 32'h7f800000;
			th6_en <= 1'b1;
			th6_acc <= 32'h7f800000;
			th7_en <= 1'b1;
			th7_acc <= 32'h7f800000;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk)
		begin
			th0_en <= 1'b0;
			th1_en <= 1'b0;
			th2_en <= 1'b0;
			th3_en <= 1'b0;
			th4_en <= 1'b0;
			th5_en <= 1'b0;
			th6_en <= 1'b0;
			th7_en <= 1'b0;
		end

		wait_pos_clk4();


		/*** Threads 3 and 4 are disabled  ***/
		@(posedge clk)
		begin
			th0_en <= 1'b1;
			th0_acc <= 32'h41800000;
			th1_en <= 1'b1;
			th1_acc <= 32'h41800000;
			th2_en <= 1'b1;
			th2_acc <= 32'h41800000;
			th5_en <= 1'b1;
			th5_acc <= 32'h41800000;
			th6_en <= 1'b1;
			th6_acc <= 32'h41800000;
			th7_en <= 1'b1;
			th7_acc <= 32'h41800000;
		end

		@(posedge clk) start <= 1'b1;
		@(posedge clk) start <= 1'b0;

		wait_pos_clk8();
		wait_pos_clk4();

		@(posedge clk)
		begin
			th0_en <= 1'b0;
			th1_en <= 1'b0;
			th2_en <= 1'b0;
			th5_en <= 1'b0;
			th6_en <= 1'b0;
			th7_en <= 1'b0;
		end

		wait_pos_clk4();


		#500 $finish;
	end



	/* Activation function execution unit */
	vxe_vpu_actf_eu actf_eu(
		.clk(clk),
		.nrst(nrst),
		.i_start(start),
		.o_busy(busy),
		.i_leaky(leaky),
		.i_expd(expd),
		.o_th(th),
		.o_ridx(ridx),
		.o_wr_en(wr_en),
		.o_data(data),
		.i_th0_acc(th0_acc),
		.i_th0_en(th0_en),
		.i_th1_acc(th1_acc),
		.i_th1_en(th1_en),
		.i_th2_acc(th2_acc),
		.i_th2_en(th2_en),
		.i_th3_acc(th3_acc),
		.i_th3_en(th3_en),
		.i_th4_acc(th4_acc),
		.i_th4_en(th4_en),
		.i_th5_acc(th5_acc),
		.i_th5_en(th5_en),
		.i_th6_acc(th6_acc),
		.i_th6_en(th6_en),
		.i_th7_acc(th7_acc),
		.i_th7_en(th7_en)
	);


endmodule /* tb_vxe_vpu_actf_eu */
