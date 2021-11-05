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
 * Testbench for VxE register I/O
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_regio();
`include "vxe_regio_params.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* RegIO interface */
	reg [9:0]	i_wreg_idx;
	reg [31:0]	i_wdata;
	reg		i_wenable;
	wire		o_waccept;
	wire		o_werror;
	reg [9:0]	i_rreg_idx;
	wire [31:0]	o_rdata;
	reg		i_renable;
	wire		o_raccept;
	wire		o_rerror;
	reg 		i_cu_busy;
	reg [36:0]	i_cu_last_instr_addr;
	reg [63:0]	i_cu_last_instr_data;
	wire [36:0]	o_cu_pgm_addr;
	wire		o_cu_start;
	reg [3:0]	i_intu_raw;
	reg [3:0]	i_intu_act;
	wire [3:0]	o_intu_msk;
	wire		o_intu_ack_vld;
	wire [3:0]	o_intu_ack;
	wire		o_cu_mas_sel;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_regio);

		clk = 1;
		nrst = 0;

		i_wenable = 1'b0;
		i_renable = 1'b0;
		i_cu_busy = 1'b1;
		i_cu_last_instr_addr = 37'h1f_0102_0304;
		i_cu_last_instr_data = 64'hbeef_deaf_cafe_feed;
		i_intu_raw = 4'hf;
		i_intu_act = 4'h7;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();

		/* Register read tests */

		@(posedge clk)
		begin
			i_rreg_idx <= REG_ID;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_CTRL;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_STATUS;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_INTR_ACT;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_INTR_MSK;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_INTR_RAW;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_PGM_ADDR_LO;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_PGM_ADDR_HI;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_START;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_FAULT_INSTR_ADDR_LO;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_FAULT_INSTR_ADDR_HI;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_FAULT_INSTR_LO;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_rreg_idx <= REG_FAULT_INSTR_HI;
			i_renable <= 1'b1;
		end
		@(posedge clk) i_renable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		/* Register write tests */

		@(posedge clk)
		begin
			i_wreg_idx <= REG_START;
			i_wenable <= 1'b1;
		end
		@(posedge clk)
		begin
			i_wenable <= 1'b0;
			i_cu_busy <= 1'b0;
		end

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_wreg_idx <= REG_START;
			i_wenable <= 1'b1;
		end
		@(posedge clk) i_wenable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_wreg_idx <= REG_CTRL;
			i_wenable <= 1'b1;
			i_wdata <= 32'h0000_0001;
		end
		@(posedge clk) i_wenable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_wreg_idx <= REG_INTR_ACT;
			i_wenable <= 1'b1;
			i_wdata <= 32'hdddd_dddc;
		end
		@(posedge clk) i_wenable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_wreg_idx <= REG_INTR_MSK;
			i_wenable <= 1'b1;
			i_wdata <= 32'hdddd_ddde;
		end
		@(posedge clk) i_wenable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_wreg_idx <= REG_PGM_ADDR_LO;
			i_wenable <= 1'b1;
			i_wdata <= 32'hcafe_beef;
		end
		@(posedge clk) i_wenable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();

		@(posedge clk)
		begin
			i_wreg_idx <= REG_PGM_ADDR_HI;
			i_wenable <= 1'b1;
			i_wdata <= 32'hdddd_abba;
		end
		@(posedge clk) i_wenable <= 1'b0;

		wait_pos_clk();
		wait_pos_clk();


		#500 $finish;
	end


	/* RegIO unit instance */
	vxe_regio regio(
		.clk(clk),
		.nrst(nrst),
		.i_wreg_idx(i_wreg_idx),
		.i_wdata(i_wdata),
		.i_wenable(i_wenable),
		.o_waccept(o_waccept),
		.o_werror(o_werror),
		.i_rreg_idx(i_rreg_idx),
		.o_rdata(o_rdata),
		.i_renable(i_renable),
		.o_raccept(o_raccept),
		.o_rerror(o_rerror),
		.i_cu_busy(i_cu_busy),
		.i_cu_last_instr_addr(i_cu_last_instr_addr),
		.i_cu_last_instr_data(i_cu_last_instr_data),
		.o_cu_pgm_addr(o_cu_pgm_addr),
		.o_cu_start(o_cu_start),
		.i_intu_raw(i_intu_raw),
		.i_intu_act(i_intu_act),
		.o_intu_msk(o_intu_msk),
		.o_intu_ack_vld(o_intu_ack_vld),
		.o_intu_ack(o_intu_ack),
		.o_cu_mas_sel(o_cu_mas_sel)
	);


endmodule /* tb_vxe_regio */
