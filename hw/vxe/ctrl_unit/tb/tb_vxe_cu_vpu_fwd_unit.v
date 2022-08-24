/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * Testbench for VxE CU VPU forwarding unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_cu_vpu_fwd_unit();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* VPU forwarding interface */
	wire		fwd_vpu_rdy;
	reg [4:0]	fwd_vpu_op;
	reg [2:0]	fwd_vpu_th;
	reg [47:0]	fwd_vpu_pl;
	reg		fwd_vpu_wr;
	/* VPU command bus interface */
	wire		vpu_cmd_sel;
	reg		vpu_cmd_ack;
	wire [4:0]	vpu_cmd_op;
	wire [2:0]	vpu_cmd_th;
	wire [47:0]	vpu_cmd_pl;
	/* Status signals */
	wire		pipes_active;

	/* Misc signals */
	reg [0:55]	test_name;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	task wait_pos_clk4;
	begin
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_cu_vpu_fwd_unit);

		clk = 1;
		nrst = 0;

		fwd_vpu_op = 0;
		fwd_vpu_th = 0;
		fwd_vpu_pl = 0;
		fwd_vpu_wr = 0;
		vpu_cmd_ack = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/**********************************************/


		/* Test 1 - Feed commands */

		@(posedge clk)
		begin
			test_name <= "Test 1 ";
			fwd_vpu_op <= 5'h1;
			fwd_vpu_th <= 3'h1;
			fwd_vpu_pl <= 48'h1;
			fwd_vpu_wr <= 1'b1;
		end

		@(posedge clk)
		begin
			fwd_vpu_op <= 5'h2;
			fwd_vpu_th <= 3'h2;
			fwd_vpu_pl <= 48'h2;
		end

		@(posedge clk)
		begin
			fwd_vpu_op <= 5'h3;
			fwd_vpu_th <= 3'h3;
			fwd_vpu_pl <= 48'h3;
		end

		@(posedge clk)
		begin
			fwd_vpu_op <= 5'h4;
			fwd_vpu_th <= 3'h4;
			fwd_vpu_pl <= 48'h4;
		end

		@(posedge clk)
		begin
			fwd_vpu_wr <= 1'b0;
		end

		wait_pos_clk4();


		/* Test 2 - Command bus busy */

		@(posedge clk)
		begin
			test_name <= "Test 2 ";
			fwd_vpu_op <= 5'h1;
			fwd_vpu_th <= 3'h1;
			fwd_vpu_pl <= 48'h1;
			fwd_vpu_wr <= 1'b1;
			vpu_cmd_ack <= 1'b0;
		end

		@(posedge clk)
		begin
			fwd_vpu_op <= 5'h2;
			fwd_vpu_th <= 3'h2;
			fwd_vpu_pl <= 48'h2;
		end

		@(posedge clk)
		begin
			fwd_vpu_op <= 5'h3;
			fwd_vpu_th <= 3'h3;
			fwd_vpu_pl <= 48'h3;
		end

		@(posedge clk)
		begin
			fwd_vpu_op <= 5'h4;
			fwd_vpu_th <= 3'h4;
			fwd_vpu_pl <= 48'h4;
		end

		@(posedge clk)
		begin
			fwd_vpu_op <= 5'h5;
			fwd_vpu_th <= 3'h5;
			fwd_vpu_pl <= 48'h5;
		end

		@(posedge clk)
		begin
			fwd_vpu_wr <= 1'b0;
			vpu_cmd_ack <= 1'b1;
		end

		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();


		#500 $finish;
	end


	/* Forwarding unit instance */
	vxe_cu_vpu_fwd_unit #(
		.DEPTH_POW2(2)
	) vpu_fwd (
		.clk(clk),
		.nrst(nrst),
		.o_fwd_vpu_rdy(fwd_vpu_rdy),
		.i_fwd_vpu_op(fwd_vpu_op),
		.i_fwd_vpu_th(fwd_vpu_th),
		.i_fwd_vpu_pl(fwd_vpu_pl),
		.i_fwd_vpu_wr(fwd_vpu_wr),
		.o_vpu_cmd_sel(vpu_cmd_sel),
		.i_vpu_cmd_ack(vpu_cmd_ack),
		.o_vpu_cmd_op(vpu_cmd_op),
		.o_vpu_cmd_th(vpu_cmd_th),
		.o_vpu_cmd_pl(vpu_cmd_pl),
		.o_pipes_active(pipes_active)
	);


endmodule /* tb_vxe_cu_vpu_fwd_unit */
