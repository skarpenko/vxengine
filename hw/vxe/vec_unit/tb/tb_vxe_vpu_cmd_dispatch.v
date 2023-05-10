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
 * Testbench for VxE VPU command dispatch unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_cmd_dispatch();
`include "vxe_ctrl_unit_cmds.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Command queue interface */
	wire		vld;
	wire		rd;
	reg [4:0]	op;
	reg [2:0]	th;
	reg [47:0]	pl;
	/* Status */
	wire		busy;
	/* Functional units interface */
	wire		regu_disp;
	reg		regu_done;
	wire		prod_disp;
	reg		prod_done;
	wire		stor_disp;
	reg		stor_done;
	wire		actf_disp;
	reg		actf_done;
	wire [4:0]	fu_cmd_op;
	wire [2:0]	fu_cmd_th;
	wire [47:0]	fu_cmd_pl;
	/* Datapath MUX control */
	wire		regu_cmd;
	wire		prod_cmd;
	wire		stor_cmd;
	wire		actf_cmd;

	/* Test control */
	reg act;
	reg [4:0] rd_ptr;

	assign vld = act && (rd_ptr < 4'd9);


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
		$dumpvars(0, tb_vxe_vpu_cmd_dispatch);

		clk = 1'b1;
		nrst = 1'b0;
		act = 1'b0;
		regu_done = 1'b0;
		prod_done = 1'b0;
		stor_done = 1'b0;
		actf_done = 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk();
		/***********************************************************/


		@(posedge clk) act <= 1'b1;

		/* Handle dispatches */

		/* 1111 */
		wait_pos_clk8();
		@(posedge clk) regu_done <= 1'b1;
		@(posedge clk) regu_done <= 1'b0;

		/* 2222 */
		wait_pos_clk8();
		@(posedge clk) regu_done <= 1'b1;
		@(posedge clk) regu_done <= 1'b0;

		/* 3333 */
		wait_pos_clk8();
		@(posedge clk) regu_done <= 1'b1;
		@(posedge clk) regu_done <= 1'b0;

		/* 4444 */
		wait_pos_clk8();
		@(posedge clk) regu_done <= 1'b1;
		@(posedge clk) regu_done <= 1'b0;

		/* 5555 */
		wait_pos_clk8();
		@(posedge clk) regu_done <= 1'b1;
		@(posedge clk) regu_done <= 1'b0;

		/* 6666 */
		wait_pos_clk8();
		@(posedge clk) regu_done <= 1'b1;
		@(posedge clk) regu_done <= 1'b0;

		/* 7777 */
		wait_pos_clk8();
		@(posedge clk) prod_done <= 1'b1;
		@(posedge clk) prod_done <= 1'b0;

		/* 0000 */
		wait_pos_clk8();
		@(posedge clk) stor_done <= 1'b1;
		@(posedge clk) stor_done <= 1'b0;

		/* 1111 */
		wait_pos_clk8();
		@(posedge clk) actf_done <= 1'b1;
		@(posedge clk) actf_done <= 1'b0;



		#500 $finish;
	end


	/* Command dispatch unit */
	vxe_vpu_cmd_dispatch cmd_disp_unit(
		.clk(clk),
		.nrst(nrst),
		.i_vld(vld),
		.o_rd(rd),
		.i_op(op),
		.i_th(th),
		.i_pl(pl),
		.o_busy(busy),
		.regu_disp(regu_disp),
		.regu_done(regu_done),
		.prod_disp(prod_disp),
		.prod_done(prod_done),
		.stor_disp(stor_disp),
		.stor_done(stor_done),
		.actf_disp(actf_disp),
		.actf_done(actf_done),
		.fu_cmd_op(fu_cmd_op),
		.fu_cmd_th(fu_cmd_th),
		.fu_cmd_pl(fu_cmd_pl),
		.regu_cmd(regu_cmd),
		.prod_cmd(prod_cmd),
		.stor_cmd(stor_cmd),
		.actf_cmd(actf_cmd)
	);


/*******************************************************************************/


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rd_ptr <= 4'd0;
	end
	else
	begin
		if(rd) rd_ptr <= rd_ptr + 1'b1;
	end
end

always @(*)
begin
	case(rd_ptr)
	4'd0: begin
		op = CU_CMD_SETACC;
		th = 3'h1;
		pl = 48'h1111;
	end
	4'd1: begin
		op = CU_CMD_SETVL;
		th = 3'h2;
		pl = 48'h2222;
	end
	4'd2: begin
		op = CU_CMD_SETEN;
		th = 3'h3;
		pl = 48'h3333;
	end
	4'd3: begin
		op = CU_CMD_SETRS;
		th = 3'h4;
		pl = 48'h4444;
	end
	4'd4: begin
		op = CU_CMD_SETRT;
		th = 3'h5;
		pl = 48'h5555;
	end
	4'd5: begin
		op = CU_CMD_SETRD;
		th = 3'h6;
		pl = 48'h6666;
	end
	4'd6: begin
		op = CU_CMD_PROD;
		th = 3'h7;
		pl = 48'h7777;
	end
	4'd7: begin
		op = CU_CMD_STORE;
		th = 3'h0;
		pl = 48'h0000;
	end
	4'd8: begin
		op = CU_CMD_ACTF;
		th = 3'h1;
		pl = 48'h1111;
	end
	default: ;
	endcase
end


endmodule /* tb_vxe_vpu_cmd_dispatch */
