/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
 * Testbench for VxE interrupt control unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_intr_unit();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* CU interface */
	reg		i_cu_intr_vld;
	reg [3:0]	i_cu_intr;
	/* RegIO interface */
	reg [3:0]	i_rio_mask;
	wire [3:0]	o_rio_raw;
	wire [3:0]	o_rio_active;
	reg		i_rio_ack_en;
	reg [3:0]	i_rio_ack;
	/* Interrupt line */
	wire		o_intr;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_intr_unit);

		clk = 1;
		nrst = 0;

		i_cu_intr_vld = 1'b0;
		i_cu_intr = 4'b000;
		i_rio_mask = 4'b000;
		i_rio_ack_en = 1'b0;
		i_rio_ack = 4'b000;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();

		@(posedge clk)
		begin
			i_cu_intr_vld <= 1'b1;
			i_cu_intr <= 4'b1010;
		end
		@(posedge clk)
			i_cu_intr_vld <= 1'b0;

		wait_pos_clk();

		@(posedge clk)
			i_rio_mask <= 4'b1000;

		wait_pos_clk();

		@(posedge clk)
			i_rio_mask <= 4'b1010;

		wait_pos_clk();

		@(posedge clk)
			i_rio_mask <= 4'b0000;

		wait_pos_clk();

		@(posedge clk)
		begin
			i_rio_ack <= 4'b1000;
			i_rio_ack_en <= 1'b1;
		end
		@(posedge clk)
			i_rio_ack_en <= 1'b0;

		wait_pos_clk();

		@(posedge clk)
		begin
			i_rio_ack <= 4'b0010;
			i_rio_ack_en <= 1'b1;
		end
		@(posedge clk)
			i_rio_ack_en <= 1'b0;

		#500 $finish;
	end


	/* Interrupt unit instance */
	vxe_intr_unit #(
		.NR_INT(4)
	) intr_unit (
		.clk(clk),
		.nrst(nrst),
		.i_cu_intr_vld(i_cu_intr_vld),
		.i_cu_intr(i_cu_intr),
		.i_rio_mask(i_rio_mask),
		.o_rio_raw(o_rio_raw),
		.o_rio_active(o_rio_active),
		.i_rio_ack_en(i_rio_ack_en),
		.i_rio_ack(i_rio_ack),
		.o_intr(o_intr)
	);


endmodule /* tb_vxe_intr_unit */
