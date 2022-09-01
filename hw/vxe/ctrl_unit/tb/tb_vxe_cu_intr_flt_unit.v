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
 * Testbench for VxE CU interrupts and faults unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_cu_intr_flt_unit();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;

	/* External interrupts and faults interface */
	wire		intr_vld;
	wire [3:0]	intr;
	wire [36:0]	last_instr_addr;
	wire [63:0]	last_instr_data;
	wire [1:0]	vpu_fault;
	/* Internal CU interface */
	reg		send_intr;
	reg		complete;
	reg		flt_fetch;
	reg [36:0]	flt_fetch_addr;
	reg		flt_decode;
	reg [36:0]	flt_decode_addr;
	reg [63:0]	flt_decode_data;
	reg [1:0]	flt_vpu;

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
		$dumpvars(0, tb_vxe_cu_intr_flt_unit);

		clk = 1;
		nrst = 0;
		send_intr = 0;
		complete = 0;
		flt_fetch = 0;
		flt_decode = 0;
		flt_vpu = 0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/**********************************************/

		/* Test 1 - completed and send interrupt */
		@(posedge clk)
		begin
			test_name <= "Test 1 ";
			send_intr <= 1'b1;
			complete <= 1'b1;
		end
		@(posedge clk)
		begin
			send_intr <= 1'b0;
			complete <= 1'b0;
		end


		wait_pos_clk4();


		/* Test 2 - fetch and decode fault */
		@(posedge clk)
		begin
			test_name <= "Test 2 ";
			send_intr <= 1'b1;
			flt_fetch <= 1'b1;
			flt_fetch_addr <= 37'hfa;
			flt_decode <= 1'b1;
			flt_decode_addr <= 37'hda;
			flt_decode_data <= 64'heeee;
		end
		@(posedge clk)
		begin
			send_intr <= 1'b0;
			flt_fetch <= 1'b0;
			flt_decode <= 1'b0;
		end


		wait_pos_clk4();


		/* Test 3 - VPUs fault */
		@(posedge clk)
		begin
			test_name <= "Test 3 ";
			flt_vpu <= 2'b01;
		end
		@(posedge clk)
		begin
			flt_vpu <= 2'b10;
			send_intr <= 1'b1;
		end
		@(posedge clk)
		begin
			flt_vpu <= 2'b00;
			send_intr <= 1'b0;
		end


		wait_pos_clk4();


		/* Test 4 - fetch fault */
		@(posedge clk)
		begin
			test_name <= "Test 4 ";
			send_intr <= 1'b1;
			flt_fetch <= 1'b1;
			flt_fetch_addr <= 37'hfaa;
		end
		@(posedge clk)
		begin
			send_intr <= 1'b0;
			flt_fetch <= 1'b0;
		end


		wait_pos_clk4();


		/* Test 5 - decode fault */
		@(posedge clk)
		begin
			test_name <= "Test 5 ";
			send_intr <= 1'b1;
			flt_decode <= 1'b1;
			flt_decode_addr <= 37'hdaaa;
			flt_decode_data <= 64'hbbbb;
		end
		@(posedge clk)
		begin
			send_intr <= 1'b0;
			flt_decode <= 1'b0;
		end


		wait_pos_clk4();


		#500 $finish;
	end


	/* Interrupts and faults unit */
	vxe_cu_intr_flt_unit #(
		.VPUS_NR(2)
	) intr_flt(
		.clk(clk),
		.nrst(nrst),
		.o_intr_vld(intr_vld),
		.o_intr(intr),
		.o_last_instr_addr(last_instr_addr),
		.o_last_instr_data(last_instr_data),
		.o_vpu_fault(vpu_fault),
		.i_send_intr(send_intr),
		.i_complete(complete),
		.i_flt_fetch(flt_fetch),
		.i_flt_fetch_addr(flt_fetch_addr),
		.i_flt_decode(flt_decode),
		.i_flt_decode_addr(flt_decode_addr),
		.i_flt_decode_data(flt_decode_data),
		.i_flt_vpu(flt_vpu)
	);


endmodule /* tb_vxe_cu_intr_flt_unit */
