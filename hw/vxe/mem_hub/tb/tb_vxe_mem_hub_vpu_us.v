/*
 * Copyright (c) 2020-2021 The VxEngine Project. All rights reserved.
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
 * Testbench for VxE VPU upstream traffic control
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_mem_hub_vpu_us();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	/* Traffic generation FSM states */
	localparam [1:0] FSM_TG_IDLE = 2'b00;	/* Idle */
	localparam [1:0] FSM_TG_RDXX = 2'b01;	/* Read source */
	localparam [1:0] FSM_TG_XXWR = 2'b10;	/* Write destination */
	localparam [1:0] FSM_TG_RDWR = 2'b11;	/* Read and write */

	reg		clk;
	reg		nrst;
	/* Request FIFOs signals */
	wire		fifo_rqa_rdy;
	reg [43:0]	fifo_rqa;
	reg		fifo_rqa_wr;
	wire		fifo_rqd_rdy;
	reg [71:0]	fifo_rqd;
	reg		fifo_rqd_wr;
	/* FIFOs for outgoing requests from master 0 */
	wire [43:0]	fifo_m0_rqa;
	reg		fifo_m0_rqa_rd;
	wire		fifo_m0_rqa_vld;
	wire [71:0]	fifo_m0_rqd;
	reg		fifo_m0_rqd_rd;
	wire		fifo_m0_rqd_vld;
	/* FIFOs for outgoing requests from master 1 */
	wire [43:0]	fifo_m1_rqa;
	reg		fifo_m1_rqa_rd;
	wire		fifo_m1_rqa_vld;
	wire [71:0]	fifo_m1_rqd;
	reg		fifo_m1_rqd_rd;
	wire		fifo_m1_rqd_vld;
	/* Request FIFOs to VPU US wires */
	wire		wire_rqa_vld;
	wire [43:0]	wire_rqa;
	wire		wire_rqa_rd;
	wire		wire_rqd_vld;
	wire [71:0]	wire_rqd;
	wire		wire_rqd_rd;
	/* VPU US to master 0 FIFOs wires */
	wire		wire_m0_rqa_rdy;
	wire [43:0]	wire_m0_rqa;
	wire		wire_m0_rqa_wr;
	wire		wire_m0_rqd_rdy;
	wire [71:0]	wire_m0_rqd;
	wire		wire_m0_rqd_wr;
	/* VPU US to master 1 FIFOs wires */
	wire		wire_m1_rqa_rdy;
	wire [43:0]	wire_m1_rqa;
	wire		wire_m1_rqa_wr;
	wire		wire_m1_rqd_rdy;
	wire [71:0]	wire_m1_rqd;
	wire		wire_m1_rqd_wr;
	/* Traffic generator on/off control */
	reg		gen_traffic;
	/* Traffic buffer FIFOs */
	reg [43:0]	bf_irqa;
	wire [43:0]	bf_orqa;
	reg		bf_rqa_rd;
	reg		bf_rqa_wr;
	wire		bf_rqa_rdy;
	wire		bf_rqa_vld;
	reg [71:0]	bf_irqd;
	wire [71:0]	bf_orqd;
	reg		bf_rqd_rd;
	reg		bf_rqd_wr;
	wire		bf_rqd_rdy;
	wire		bf_rqd_vld;
	reg [0:47]	test_name;


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


	task wait_pos_clk16;
	begin
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
		wait_pos_clk4();
	end
	endtask


	task wait_pos_clk32;
	begin
		wait_pos_clk16();
		wait_pos_clk16();
	end
	endtask


	task wait_pos_clk64;
	begin
		wait_pos_clk32();
		wait_pos_clk32();
	end
	endtask


	task wait_pos_clk128;
	begin
		wait_pos_clk64();
		wait_pos_clk64();
	end
	endtask


	/* Write request to traffic buffer FIFOs */
	task bf_write;
	input [43:0] addr;
	input data_valid;
	input [71:0] data;
	begin
		@(posedge clk)
		begin
			bf_irqa <= addr;
			bf_rqa_wr <= 1'b1;
			if(data_valid)
			begin
				bf_irqd <= data;
				bf_rqd_wr <= 1'b1;
			end
		end
		@(posedge clk)
		begin
			bf_rqa_wr <= 1'b0;
			bf_rqd_wr <= 1'b0;
		end
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_mem_hub_vpu_us);

		clk = 1;
		nrst = 0;

		fifo_m0_rqa_rd = 1'b0;
		fifo_m0_rqd_rd = 1'b0;
		fifo_m1_rqa_rd = 1'b0;
		fifo_m1_rqd_rd = 1'b0;

		bf_rqa_wr = 1'b0;
		bf_rqd_wr = 1'b0;

		gen_traffic = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();


		/** Sequence of writes for M0 then for M1 **/

		@(posedge clk) test_name <= "Test_1";

		/* Prepare write traffic for M0 */
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000001}, 1'b1, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000002}, 1'b1, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000003}, 1'b1, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000004}, 1'b1, { 8'hFF, 64'hDD000004});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000005}, 1'b1, { 8'hFF, 64'hDD000005});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000006}, 1'b1, { 8'hFF, 64'hDD000006});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000007}, 1'b1, { 8'hFF, 64'hDD000007});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000008}, 1'b1, { 8'hFF, 64'hDD000008});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000009}, 1'b1, { 8'hFF, 64'hDD000009});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000A}, 1'b1, { 8'hFF, 64'hDD00000A});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000B}, 1'b1, { 8'hFF, 64'hDD00000B});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000C}, 1'b1, { 8'hFF, 64'hDD00000C});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000D}, 1'b1, { 8'hFF, 64'hDD00000D});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000E}, 1'b1, { 8'hFF, 64'hDD00000E});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000F}, 1'b1, { 8'hFF, 64'hDD00000F});


		/* Prepare write traffic for M1 */
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010001}, 1'b1, { 8'hFF, 64'hDD010001});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010002}, 1'b1, { 8'hFF, 64'hDD010002});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010003}, 1'b1, { 8'hFF, 64'hDD010003});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010004}, 1'b1, { 8'hFF, 64'hDD010004});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010005}, 1'b1, { 8'hFF, 64'hDD010005});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010006}, 1'b1, { 8'hFF, 64'hDD010006});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010007}, 1'b1, { 8'hFF, 64'hDD010007});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010008}, 1'b1, { 8'hFF, 64'hDD010008});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010009}, 1'b1, { 8'hFF, 64'hDD010009});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000A}, 1'b1, { 8'hFF, 64'hDD01000A});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000B}, 1'b1, { 8'hFF, 64'hDD01000B});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000C}, 1'b1, { 8'hFF, 64'hDD01000C});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000D}, 1'b1, { 8'hFF, 64'hDD01000D});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000E}, 1'b1, { 8'hFF, 64'hDD01000E});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000F}, 1'b1, { 8'hFF, 64'hDD01000F});


		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		wait_pos_clk128();


		/** Sequence of interleaved writes for M0 and M1 **/

		@(posedge clk) test_name <= "Test_2";

		/* Prepare write traffic for M0 and M1 (interleaved) */
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000001}, 1'b1, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010001}, 1'b1, { 8'hFF, 64'hDD010001});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000002}, 1'b1, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010002}, 1'b1, { 8'hFF, 64'hDD010002});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000003}, 1'b1, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010003}, 1'b1, { 8'hFF, 64'hDD010003});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000004}, 1'b1, { 8'hFF, 64'hDD000004});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010004}, 1'b1, { 8'hFF, 64'hDD010004});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000005}, 1'b1, { 8'hFF, 64'hDD000005});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010005}, 1'b1, { 8'hFF, 64'hDD010005});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000006}, 1'b1, { 8'hFF, 64'hDD000006});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010006}, 1'b1, { 8'hFF, 64'hDD010006});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000007}, 1'b1, { 8'hFF, 64'hDD000007});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010007}, 1'b1, { 8'hFF, 64'hDD010007});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000008}, 1'b1, { 8'hFF, 64'hDD000008});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010008}, 1'b1, { 8'hFF, 64'hDD010008});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000009}, 1'b1, { 8'hFF, 64'hDD000009});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010009}, 1'b1, { 8'hFF, 64'hDD010009});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000A}, 1'b1, { 8'hFF, 64'hDD00000A});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000A}, 1'b1, { 8'hFF, 64'hDD01000A});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000B}, 1'b1, { 8'hFF, 64'hDD00000B});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000B}, 1'b1, { 8'hFF, 64'hDD01000B});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000C}, 1'b1, { 8'hFF, 64'hDD00000C});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000C}, 1'b1, { 8'hFF, 64'hDD01000C});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000D}, 1'b1, { 8'hFF, 64'hDD00000D});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000D}, 1'b1, { 8'hFF, 64'hDD01000D});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000E}, 1'b1, { 8'hFF, 64'hDD00000E});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000E}, 1'b1, { 8'hFF, 64'hDD01000E});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00000F}, 1'b1, { 8'hFF, 64'hDD00000F});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA01000F}, 1'b1, { 8'hFF, 64'hDD01000F});

		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		wait_pos_clk128();


		/** Sequence of reads for M0 then for M1 **/

		@(posedge clk) test_name <= "Test_3";

		/* Prepare read traffic for M0 */
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000001}, 1'b0, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000002}, 1'b0, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000003}, 1'b0, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000004}, 1'b0, { 8'hFF, 64'hDD000004});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000005}, 1'b0, { 8'hFF, 64'hDD000005});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000006}, 1'b0, { 8'hFF, 64'hDD000006});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000007}, 1'b0, { 8'hFF, 64'hDD000007});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000008}, 1'b0, { 8'hFF, 64'hDD000008});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA000009}, 1'b0, { 8'hFF, 64'hDD000009});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA00000A}, 1'b0, { 8'hFF, 64'hDD00000A});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA00000B}, 1'b0, { 8'hFF, 64'hDD00000B});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA00000C}, 1'b0, { 8'hFF, 64'hDD00000C});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA00000D}, 1'b0, { 8'hFF, 64'hDD00000D});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA00000E}, 1'b0, { 8'hFF, 64'hDD00000E});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b1, 37'hAA00000F}, 1'b0, { 8'hFF, 64'hDD00000F});


		/* Prepare read traffic for M1 */
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010001}, 1'b0, { 8'hFF, 64'hDD010001});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010002}, 1'b0, { 8'hFF, 64'hDD010002});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010003}, 1'b0, { 8'hFF, 64'hDD010003});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010004}, 1'b0, { 8'hFF, 64'hDD010004});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010005}, 1'b0, { 8'hFF, 64'hDD010005});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010006}, 1'b0, { 8'hFF, 64'hDD010006});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010007}, 1'b0, { 8'hFF, 64'hDD010007});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010008}, 1'b0, { 8'hFF, 64'hDD010008});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA010009}, 1'b0, { 8'hFF, 64'hDD010009});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA01000A}, 1'b0, { 8'hFF, 64'hDD01000A});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA01000B}, 1'b0, { 8'hFF, 64'hDD01000B});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA01000C}, 1'b0, { 8'hFF, 64'hDD01000C});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA01000D}, 1'b0, { 8'hFF, 64'hDD01000D});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA01000E}, 1'b0, { 8'hFF, 64'hDD01000E});
		bf_write({ 2'b10, 3'b000, 1'b1, 1'b1, 37'hAA01000F}, 1'b0, { 8'hFF, 64'hDD01000F});


		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		wait_pos_clk128();


		/** Sequence of interleaved reads for M0 and M1 **/

		@(posedge clk) test_name <= "Test_4";

		/* Prepare read traffic for M0 and M1 (interleaved) */
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000001}, 1'b0, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010001}, 1'b0, { 8'hFF, 64'hDD010001});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000002}, 1'b0, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010002}, 1'b0, { 8'hFF, 64'hDD010002});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000003}, 1'b0, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010003}, 1'b0, { 8'hFF, 64'hDD010003});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000004}, 1'b0, { 8'hFF, 64'hDD000004});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010004}, 1'b0, { 8'hFF, 64'hDD010004});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000005}, 1'b0, { 8'hFF, 64'hDD000005});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010005}, 1'b0, { 8'hFF, 64'hDD010005});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000006}, 1'b0, { 8'hFF, 64'hDD000006});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010006}, 1'b0, { 8'hFF, 64'hDD010006});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000007}, 1'b0, { 8'hFF, 64'hDD000007});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010007}, 1'b0, { 8'hFF, 64'hDD010007});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000008}, 1'b0, { 8'hFF, 64'hDD000008});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010008}, 1'b0, { 8'hFF, 64'hDD010008});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000009}, 1'b0, { 8'hFF, 64'hDD000009});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010009}, 1'b0, { 8'hFF, 64'hDD010009});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000A}, 1'b0, { 8'hFF, 64'hDD00000A});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000A}, 1'b0, { 8'hFF, 64'hDD01000A});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000B}, 1'b0, { 8'hFF, 64'hDD00000B});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000B}, 1'b0, { 8'hFF, 64'hDD01000B});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000C}, 1'b0, { 8'hFF, 64'hDD00000C});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000C}, 1'b0, { 8'hFF, 64'hDD01000C});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000D}, 1'b0, { 8'hFF, 64'hDD00000D});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000D}, 1'b0, { 8'hFF, 64'hDD01000D});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000E}, 1'b0, { 8'hFF, 64'hDD00000E});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000E}, 1'b0, { 8'hFF, 64'hDD01000E});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000F}, 1'b0, { 8'hFF, 64'hDD00000F});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000F}, 1'b0, { 8'hFF, 64'hDD01000F});

		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		wait_pos_clk128();


		/** Sequence of interleaved reads and writes for M0 and M1 **/

		@(posedge clk) test_name <= "Test_5";

		/* Prepare read/write traffic for M0 and M1 (interleaved) */
		/* Reads for M0 writes for M1 */
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000001}, 1'b0, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000002}, 1'b0, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000003}, 1'b0, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000004}, 1'b0, { 8'hFF, 64'hDD000004});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000005}, 1'b0, { 8'hFF, 64'hDD000005});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000006}, 1'b0, { 8'hFF, 64'hDD000006});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010001}, 1'b1, { 8'hFF, 64'hDD010001});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010002}, 1'b1, { 8'hFF, 64'hDD010002});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA010003}, 1'b1, { 8'hFF, 64'hDD010003});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000007}, 1'b0, { 8'hFF, 64'hDD000007});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000008}, 1'b0, { 8'hFF, 64'hDD000008});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000009}, 1'b0, { 8'hFF, 64'hDD000009});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000A}, 1'b0, { 8'hFF, 64'hDD00000A});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000B}, 1'b0, { 8'hFF, 64'hDD00000B});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000C}, 1'b0, { 8'hFF, 64'hDD00000C});

		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		wait_pos_clk128();


		/** Sequence of interleaved reads and writes for M0 and M1 **/

		@(posedge clk) test_name <= "Test_6";

		/* Prepare read/write traffic for M0 and M1 (interleaved) */
		/* Reads for M1 writes for M0 */
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010001}, 1'b0, { 8'hFF, 64'hDD010001});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010002}, 1'b0, { 8'hFF, 64'hDD010002});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010003}, 1'b0, { 8'hFF, 64'hDD010003});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010004}, 1'b0, { 8'hFF, 64'hDD010004});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010005}, 1'b0, { 8'hFF, 64'hDD010005});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010006}, 1'b0, { 8'hFF, 64'hDD010006});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000001}, 1'b1, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000002}, 1'b1, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA000003}, 1'b1, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010007}, 1'b0, { 8'hFF, 64'hDD010007});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010008}, 1'b0, { 8'hFF, 64'hDD010008});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA010009}, 1'b0, { 8'hFF, 64'hDD010009});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000A}, 1'b0, { 8'hFF, 64'hDD01000A});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000B}, 1'b0, { 8'hFF, 64'hDD01000B});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA01000C}, 1'b0, { 8'hFF, 64'hDD01000C});

		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		wait_pos_clk128();


		/** Sequence of interleaved reads and writes for M0 **/

		@(posedge clk) test_name <= "Test_7";

		/* Prepare read/write traffic for M0 */
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000001}, 1'b0, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000002}, 1'b0, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000003}, 1'b0, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000004}, 1'b0, { 8'hFF, 64'hDD000004});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000005}, 1'b0, { 8'hFF, 64'hDD000005});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000006}, 1'b0, { 8'hFF, 64'hDD000006});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00B001}, 1'b1, { 8'hFF, 64'hDD00B001});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00B002}, 1'b1, { 8'hFF, 64'hDD00B002});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b0, 37'hAA00B003}, 1'b1, { 8'hFF, 64'hDD00B003});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000007}, 1'b0, { 8'hFF, 64'hDD000007});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000008}, 1'b0, { 8'hFF, 64'hDD000008});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA000009}, 1'b0, { 8'hFF, 64'hDD000009});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000A}, 1'b0, { 8'hFF, 64'hDD00000A});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000B}, 1'b0, { 8'hFF, 64'hDD00000B});
		bf_write({ 2'b01, 3'b000, 1'b0, 1'b1, 37'hAA00000C}, 1'b0, { 8'hFF, 64'hDD00000C});

		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		wait_pos_clk128();


		/** Sequence of interleaved reads and writes for M1 **/

		@(posedge clk) test_name <= "Test_8";

		/* Prepare read/write traffic for M1 */
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000001}, 1'b0, { 8'hFF, 64'hDD000001});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000002}, 1'b0, { 8'hFF, 64'hDD000002});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000003}, 1'b0, { 8'hFF, 64'hDD000003});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000004}, 1'b0, { 8'hFF, 64'hDD000004});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000005}, 1'b0, { 8'hFF, 64'hDD000005});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000006}, 1'b0, { 8'hFF, 64'hDD000006});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA00B001}, 1'b1, { 8'hFF, 64'hDD00B001});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA00B002}, 1'b1, { 8'hFF, 64'hDD00B002});
		bf_write({ 2'b10, 3'b000, 1'b0, 1'b0, 37'hAA00B003}, 1'b1, { 8'hFF, 64'hDD00B003});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000007}, 1'b0, { 8'hFF, 64'hDD000007});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000008}, 1'b0, { 8'hFF, 64'hDD000008});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA000009}, 1'b0, { 8'hFF, 64'hDD000009});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA00000A}, 1'b0, { 8'hFF, 64'hDD00000A});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA00000B}, 1'b0, { 8'hFF, 64'hDD00000B});
		bf_write({ 2'b01, 3'b000, 1'b1, 1'b1, 37'hAA00000C}, 1'b0, { 8'hFF, 64'hDD00000C});

		@(posedge clk) gen_traffic <= 1'b1;

		wait_pos_clk64();

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b1;
			fifo_m0_rqd_rd <= 1'b1;
			fifo_m1_rqa_rd <= 1'b1;
			fifo_m1_rqd_rd <= 1'b1;
		end

		wait_pos_clk64();

		@(posedge clk) gen_traffic <= 1'b0;

		@(posedge clk)
		begin
			fifo_m0_rqa_rd <= 1'b0;
			fifo_m0_rqd_rd <= 1'b0;
			fifo_m1_rqa_rd <= 1'b0;
			fifo_m1_rqd_rd <= 1'b0;
		end


		#500 $finish;
	end


	/* VPU upstream */
	vxe_mem_hub_vpu_us vpu_us(
		.clk(clk),
		.nrst(nrst),
		.i_rqa_vld(wire_rqa_vld),
		.i_rqa(wire_rqa),
		.o_rqa_rd(wire_rqa_rd),
		.i_rqd_vld(wire_rqd_vld),
		.i_rqd(wire_rqd),
		.o_rqd_rd(wire_rqd_rd),
		.i_m0_rqa_rdy(wire_m0_rqa_rdy),
		.o_m0_rqa(wire_m0_rqa),
		.o_m0_rqa_wr(wire_m0_rqa_wr),
		.i_m0_rqd_rdy(wire_m0_rqd_rdy),
		.o_m0_rqd(wire_m0_rqd),
		.o_m0_rqd_wr(wire_m0_rqd_wr),
		.i_m1_rqa_rdy(wire_m1_rqa_rdy),
		.o_m1_rqa(wire_m1_rqa),
		.o_m1_rqa_wr(wire_m1_rqa_wr),
		.i_m1_rqd_rdy(wire_m1_rqd_rdy),
		.o_m1_rqd(wire_m1_rqd),
		.o_m1_rqd_wr(wire_m1_rqd_wr)
	);


	/* Incoming request address FIFO */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) reqaf (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqa),
		.data_out(wire_rqa),
		.rd(wire_rqa_rd),
		.wr(fifo_rqa_wr),
		.in_rdy(fifo_rqa_rdy),
		.out_vld(wire_rqa_vld)
	);


	/* Incoming request data FIFO */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) reqdf (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqd),
		.data_out(wire_rqd),
		.rd(wire_rqd_rd),
		.wr(fifo_rqd_wr),
		.in_rdy(fifo_rqd_rdy),
		.out_vld(wire_rqd_vld)
	);


	/* Outgoing request address FIFO for master 0 */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) m0af (
		.clk(clk),
		.nrst(nrst),
		.data_in(wire_m0_rqa),
		.data_out(fifo_m0_rqa),
		.rd(fifo_m0_rqa_rd),
		.wr(wire_m0_rqa_wr),
		.in_rdy(wire_m0_rqa_rdy),
		.out_vld(fifo_m0_rqa_vld)
	);


	/* Outgoing request data FIFO for master 0 */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) m0df (
		.clk(clk),
		.nrst(nrst),
		.data_in(wire_m0_rqd),
		.data_out(fifo_m0_rqd),
		.rd(fifo_m0_rqd_rd),
		.wr(wire_m0_rqd_wr),
		.in_rdy(wire_m0_rqd_rdy),
		.out_vld(fifo_m0_rqd_vld)
	);


	/* Outgoing request address FIFO for master 1 */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) m1af (
		.clk(clk),
		.nrst(nrst),
		.data_in(wire_m1_rqa),
		.data_out(fifo_m1_rqa),
		.rd(fifo_m1_rqa_rd),
		.wr(wire_m1_rqa_wr),
		.in_rdy(wire_m1_rqa_rdy),
		.out_vld(fifo_m1_rqa_vld)
	);


	/* Outgoing request data FIFO for master 1 */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) m1df (
		.clk(clk),
		.nrst(nrst),
		.data_in(wire_m1_rqd),
		.data_out(fifo_m1_rqd),
		.rd(fifo_m1_rqd_rd),
		.wr(wire_m1_rqd_wr),
		.in_rdy(wire_m1_rqd_rdy),
		.out_vld(fifo_m1_rqd_vld)
	);


	/** Simple traffic generation **/

	/* Request address buffer FIFO */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(5)
	) reqabf (
		.clk(clk),
		.nrst(nrst),
		.data_in(bf_irqa),
		.data_out(bf_orqa),
		.rd(bf_rqa_rd),
		.wr(bf_rqa_wr),
		.in_rdy(bf_rqa_rdy),
		.out_vld(bf_rqa_vld)
	);


	/* Request data buffer FIFO */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(5)
	) reqdbf (
		.clk(clk),
		.nrst(nrst),
		.data_in(bf_irqd),
		.data_out(bf_orqd),
		.rd(bf_rqd_rd),
		.wr(bf_rqd_wr),
		.in_rdy(bf_rqd_rdy),
		.out_vld(bf_rqd_vld)
	);


reg [1:0]	afsm_state;
reg [43:0]	astash_q;	/* Temporary storage */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		afsm_state <= FSM_TG_IDLE;
		bf_rqa_rd <= 1'b0;
		fifo_rqa_wr <= 1'b0;
	end
	else if(gen_traffic)
	begin
		case(afsm_state)
		FSM_TG_RDXX: begin
			if(bf_rqa_vld)
			begin
				fifo_rqa <= bf_orqa;
				fifo_rqa_wr <= 1'b1;
				afsm_state <= FSM_TG_RDWR;
			end
		end
		FSM_TG_XXWR: begin
			if(fifo_rqa_rdy)
			begin
				fifo_rqa <= astash_q;
				bf_rqa_rd <= 1'b1;
				afsm_state <= FSM_TG_RDWR;
			end
		end
		FSM_TG_RDWR: begin
			if(bf_rqa_vld && fifo_rqa_rdy)
			begin
				fifo_rqa <= bf_orqa;
			end
			else if(bf_rqa_vld && !fifo_rqa_rdy)
			begin
				astash_q <= bf_orqa;
				bf_rqa_rd <= 1'b0;
				afsm_state <= FSM_TG_XXWR;
			end
			else if(!bf_rqa_vld && fifo_rqa_rdy)
			begin
				fifo_rqa_wr <= 1'b0;
				afsm_state <= FSM_TG_RDXX;
			end
		end
		default: begin
			bf_rqa_rd <= 1'b1;
			afsm_state <= FSM_TG_RDXX;
		end
		endcase
	end
	else
	begin
		afsm_state <= FSM_TG_IDLE;
		bf_rqa_rd <= 1'b0;
		fifo_rqa_wr <= 1'b0;
	end
end


reg [1:0]	dfsm_state;
reg [71:0]	dstash_q;	/* Temporary storage */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		dfsm_state <= FSM_TG_IDLE;
		bf_rqd_rd <= 1'b0;
		fifo_rqd_wr <= 1'b0;
	end
	else if(gen_traffic)
	begin
		case(dfsm_state)
		FSM_TG_RDXX: begin
			if(bf_rqd_vld)
			begin
				fifo_rqd <= bf_orqd;
				fifo_rqd_wr <= 1'b1;
				dfsm_state <= FSM_TG_RDWR;
			end
		end
		FSM_TG_XXWR: begin
			if(fifo_rqd_rdy)
			begin
				fifo_rqd <= dstash_q;
				bf_rqd_rd <= 1'b1;
				dfsm_state <= FSM_TG_RDWR;
			end
		end
		FSM_TG_RDWR: begin
			if(bf_rqd_vld && fifo_rqd_rdy)
			begin
				fifo_rqd <= bf_orqd;
			end
			else if(bf_rqd_vld && !fifo_rqd_rdy)
			begin
				dstash_q <= bf_orqd;
				bf_rqd_rd <= 1'b0;
				dfsm_state <= FSM_TG_XXWR;
			end
			else if(!bf_rqd_vld && fifo_rqd_rdy)
			begin
				fifo_rqd_wr <= 1'b0;
				dfsm_state <= FSM_TG_RDXX;
			end
		end
		default: begin
			bf_rqd_rd <= 1'b1;
			dfsm_state <= FSM_TG_RDXX;
		end
		endcase
	end
	else
	begin
		dfsm_state <= FSM_TG_IDLE;
		bf_rqd_rd <= 1'b0;
		fifo_rqd_wr <= 1'b0;
	end
end


endmodule /* tb_vxe_mem_hub_vpu_us */
