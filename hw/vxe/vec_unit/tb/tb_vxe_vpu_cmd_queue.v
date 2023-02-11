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
 * Testbench for VxE VPU command queue
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_cmd_queue();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Control */
	reg		en;
	reg		dis;
	wire		busy;
	/* Ingoing commands */
	reg		cmd_sel;
	wire		cmd_ack;
	reg [4:0]	cmd_op;
	reg [2:0]	cmd_th;
	reg [47:0]	cmd_pl;
	/* Outgoing commands */
	wire		vld;
	reg		rd;
	wire [4:0]	op;
	wire [2:0]	th;
	wire [47:0]	pl;


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
		$dumpvars(0, tb_vxe_vpu_cmd_queue);

		clk = 1'b1;
		nrst = 1'b0;
		en = 1'b0;
		dis = 1'b0;
		cmd_sel = 1'b0;
		rd = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk();
		/***********************************************************/

		/* Sequence of writes without enabling */
		@(posedge clk)
		begin
			cmd_sel <= 1'b1;
			cmd_op <= 5'h0f;
			cmd_th <= 3'h02;
			cmd_pl <= 48'h0febe;
		end
		
		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) cmd_sel <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk4();


		/* Enable, write then read  */
		@(posedge clk) en <= 1'b1;

		@(posedge clk)
		begin
			en <= 1'b0;
			cmd_sel <= 1'b1;
			cmd_op <= 5'hf0;
			cmd_th <= 3'h03;
			cmd_pl <= 48'h0fa00;
		end

		@(posedge clk) cmd_pl <= 48'h0fa01;
		@(posedge clk) cmd_pl <= 48'h0fa02;
		@(posedge clk) cmd_pl <= 48'h0fa03;
		@(posedge clk) cmd_pl <= 48'h0fa04;

		@(posedge clk) cmd_sel <= 1'b0;

		@(posedge clk) rd <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) rd <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk4();


		/* Write, disable, then write, then read  */
		@(posedge clk)
		begin
			cmd_sel <= 1'b1;
			cmd_op <= 5'hfa;
			cmd_th <= 3'h01;
			cmd_pl <= 48'h0be00;
		end

		@(posedge clk) cmd_pl <= 48'h0be01;
		@(posedge clk) cmd_pl <= 48'h0be02;
		@(posedge clk) cmd_pl <= 48'h0be03;
		@(posedge clk) cmd_pl <= 48'h0be04;

		@(posedge clk) cmd_sel <= 1'b0;

		@(posedge clk) dis <= 1'b1;
		@(posedge clk) dis <= 1'b0;

		@(posedge clk)
		begin
			cmd_sel <= 1'b1;
			cmd_op <= 5'hbe;
			cmd_th <= 3'h07;
			cmd_pl <= 48'h0ae00;
		end

		@(posedge clk) cmd_pl <= 48'h0ae01;
		@(posedge clk) cmd_pl <= 48'h0ae02;
		@(posedge clk) cmd_pl <= 48'h0ae03;
		@(posedge clk) cmd_pl <= 48'h0ae04;
		
		@(posedge clk) cmd_sel <= 1'b0;

		@(posedge clk) rd <= 1'b1;

		wait_pos_clk4();
		wait_pos_clk4();

		@(posedge clk) rd <= 1'b0;

		wait_pos_clk4();
		wait_pos_clk4();


		#500 $finish;
	end


	/* Command queue instance */
	vxe_vpu_cmd_queue #(
		.DEPTH_POW2(2)
	) cmd_queue (
		.clk(clk),
		.nrst(nrst),
		.i_enable(en),
		.i_disable(dis),
		.o_busy(busy),
		.i_cmd_sel(cmd_sel),
		.o_cmd_ack(cmd_ack),
		.i_cmd_op(cmd_op),
		.i_cmd_th(cmd_th),
		.i_cmd_pl(cmd_pl),
		.o_vld(vld),
		.i_rd(rd),
		.o_op(op),
		.o_th(th),
		.o_pl(pl)
	);


endmodule /* tb_vxe_vpu_cmd_queue */
