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
 * Testbench for VxE VPU thread register file
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_thread_rf();
`include "vxe_vpu_regidx_params.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* RF interface  */
	reg [2:0]	ridx;
	reg		wr_en;
	reg [37:0]	data;
	wire [31:0]	out_acc;
	wire [19:0]	out_vl;
	wire		out_en;
	wire [37:0]	out_rs;
	wire [37:0]	out_rt;
	wire [37:0]	out_rd;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_thread_rf);

		clk = 1'b1;
		nrst = 1'b0;
		wr_en = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk();
		/***********************************************************/

		wait_pos_clk();

		@(posedge clk)
		begin
			ridx <= VPU_REG_IDX_ACC;
			wr_en <= 1'b1;
			data <= 38'h00001;
		end
		@(posedge clk) wr_en <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			ridx <= VPU_REG_IDX_VL;
			wr_en <= 1'b1;
			data <= 38'h00002;
		end
		@(posedge clk) wr_en <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			ridx <= VPU_REG_IDX_EN;
			wr_en <= 1'b1;
			data <= 38'h00001;
		end
		@(posedge clk) wr_en <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			ridx <= VPU_REG_IDX_EN;
			wr_en <= 1'b1;
			data <= 38'h00000;
		end
		@(posedge clk) wr_en <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			ridx <= VPU_REG_IDX_RS;
			wr_en <= 1'b1;
			data <= 38'h00003;
		end
		@(posedge clk) wr_en <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			ridx <= VPU_REG_IDX_RT;
			wr_en <= 1'b1;
			data <= 38'h00004;
		end
		@(posedge clk) wr_en <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			ridx <= VPU_REG_IDX_RD;
			wr_en <= 1'b1;
			data <= 38'h00005;
		end
		@(posedge clk) wr_en <= 1'b0;



		#500 $finish;
	end


	/* Thread register file */
	vxe_vpu_thread_rf thread_rf(
		.clk(clk),
		.nrst(nrst),
		.ridx(ridx),
		.wr_en(wr_en),
		.data(data),
		.out_acc(out_acc),
		.out_vl(out_vl),
		.out_en(out_en),
		.out_rs(out_rs),
		.out_rt(out_rt),
		.out_rd(out_rd)
	);


endmodule /* tb_vxe_vpu_thread_rf */
