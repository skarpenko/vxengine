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
 * Testbench for VxE CU execute unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_cu_exec_unit();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;


	/* External CU interface */
	reg		start;
	wire		glb_busy;
	/* Internal control interface */
	wire		halt;
	wire		unhalt;
	wire		stop_drain;
	wire		send_intr;
	wire		complete;
	/* Command state interface */
	reg		cmd_nop;
	reg		cmd_sync;
	reg		cmd_sync_stop;
	reg		cmd_sync_intr;
	/* Internal busy signals */
	reg		fetch_busy;
	reg		dis_pipes_active;
	reg		fwd_pipes_active;
	reg [1:0]	vpus_busy;
	/* Internal fault signals */
	reg		flt_fetch;
	reg		flt_decode;
	reg [1:0]	vpus_err;

	reg [0:55]	test_name;


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


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_cu_exec_unit);

		clk = 1;
		nrst = 0;
		start = 1'b0;
		cmd_nop = 1'b0;
		cmd_sync = 1'b0;
		cmd_sync_stop = 1'b0;
		cmd_sync_intr = 1'b0;
		fetch_busy = 1'b0;
		dis_pipes_active = 1'b0;
		fwd_pipes_active = 1'b0;
		vpus_busy = 2'b00;
		flt_fetch = 1'b0;
		flt_decode = 1'b0;
		vpus_err = 2'b00;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/**********************************************/

		/* Test 1 - start and stop execution */
		@(posedge clk)
		begin
			test_name <= "Test 1 ";
			start <= 1'b1;
			fetch_busy <= 1'b1;
			dis_pipes_active <= 1'b1;
			fwd_pipes_active <= 1'b1;
			vpus_busy <= 2'b11;
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			cmd_sync <= 1'b1;
			cmd_sync_stop <= 1'b1;
		end
		@(posedge clk)
		begin
			cmd_sync <= 1'b0;
			cmd_sync_stop <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			fetch_busy <= 1'b0;
			dis_pipes_active <= 1'b0;
			fwd_pipes_active <= 1'b0;
			vpus_busy <= 2'b00;
		end

		wait_pos_clk4();


		/* Test 2 - start execution then sync and stop with interrupt */
		@(posedge clk)
		begin
			test_name <= "Test 2 ";
			start <= 1'b1;
			fetch_busy <= 1'b1;
			dis_pipes_active <= 1'b1;
			fwd_pipes_active <= 1'b1;
			vpus_busy <= 2'b11;
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			cmd_sync <= 1'b1;
		end
		@(posedge clk)
		begin
			cmd_sync <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			fwd_pipes_active <= 1'b0;
			vpus_busy <= 2'b00;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			cmd_sync <= 1'b1;
			cmd_sync_stop <= 1'b1;
			cmd_sync_intr <= 1'b1;
		end
		@(posedge clk)
		begin
			cmd_sync <= 1'b0;
			cmd_sync_stop <= 1'b0;
			cmd_sync_intr <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			fetch_busy <= 1'b0;
			dis_pipes_active <= 1'b0;
		end

		wait_pos_clk4();


		/* Test 3 - start execution then handle faults */
		@(posedge clk)
		begin
			test_name <= "Test 3 ";
			start <= 1'b1;
			fetch_busy <= 1'b1;
			dis_pipes_active <= 1'b1;
			fwd_pipes_active <= 1'b1;
			vpus_busy <= 2'b11;
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			flt_fetch <= 1'b1;
			flt_decode <= 1'b1;
			vpus_err <= 2'b11;
		end
		@(posedge clk)
		begin
			flt_fetch <= 1'b0;
			flt_decode <= 1'b0;
			vpus_err <= 2'b00;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			fetch_busy <= 1'b0;
			dis_pipes_active <= 1'b0;
			fwd_pipes_active <= 1'b0;
			vpus_busy <= 2'b00;
		end

		wait_pos_clk4();


		/* Test 4 - start execution then stop with interrupt and faults */
		@(posedge clk)
		begin
			test_name <= "Test 4 ";
			start <= 1'b1;
			fetch_busy <= 1'b1;
			dis_pipes_active <= 1'b1;
			fwd_pipes_active <= 1'b1;
			vpus_busy <= 2'b11;
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			cmd_sync <= 1'b1;
			cmd_sync_stop <= 1'b1;
			cmd_sync_intr <= 1'b1;
			flt_fetch <= 1'b1;
			flt_decode <= 1'b1;
		end
		@(posedge clk)
		begin
			cmd_sync <= 1'b0;
			cmd_sync_stop <= 1'b0;
			cmd_sync_intr <= 1'b0;
			flt_fetch <= 1'b0;
			flt_decode <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			fetch_busy <= 1'b0;
			dis_pipes_active <= 1'b0;
			fwd_pipes_active <= 1'b0;
			vpus_busy <= 2'b00;
		end

		wait_pos_clk4();


		/* Test 5 - start execution then nop and then stop with interrupt */
		@(posedge clk)
		begin
			test_name <= "Test 5 ";
			start <= 1'b1;
			fetch_busy <= 1'b1;
			dis_pipes_active <= 1'b1;
			fwd_pipes_active <= 1'b1;
			vpus_busy <= 2'b11;
		end
		@(posedge clk)
		begin
			start <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			cmd_nop <= 1'b1;
		end
		@(posedge clk)
		begin
			cmd_nop <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			cmd_sync <= 1'b1;
			cmd_sync_stop <= 1'b1;
			cmd_sync_intr <= 1'b1;
		end
		@(posedge clk)
		begin
			cmd_sync <= 1'b0;
			cmd_sync_stop <= 1'b0;
			cmd_sync_intr <= 1'b0;
		end

		wait_pos_clk4();

		@(posedge clk)
		begin
			fetch_busy <= 1'b0;
			dis_pipes_active <= 1'b0;
			fwd_pipes_active <= 1'b0;
			vpus_busy <= 2'b00;
		end

		wait_pos_clk4();


		#500 $finish;
	end


	/* Execute unit */
	vxe_cu_exec_unit #(
		.VPUS_NR(2)
	) exec_unit(
		.clk(clk),
		.nrst(nrst),
		.i_start(start),
		.o_glb_busy(glb_busy),
		.o_halt(halt),
		.o_unhalt(unhalt),
		.o_stop_drain(stop_drain),
		.o_send_intr(send_intr),
		.o_complete(complete),
		.i_cmd_nop(cmd_nop),
		.i_cmd_sync(cmd_sync),
		.i_cmd_sync_stop(cmd_sync_stop),
		.i_cmd_sync_intr(cmd_sync_intr),
		.i_fetch_busy(fetch_busy),
		.i_dis_pipes_active(dis_pipes_active),
		.i_fwd_pipes_active(fwd_pipes_active),
		.i_vpus_busy(vpus_busy),
		.i_flt_fetch(flt_fetch),
		.i_flt_decode(flt_decode),
		.i_vpus_err(vpus_err)
	);


endmodule /* tb_vxe_cu_exec_unit */
