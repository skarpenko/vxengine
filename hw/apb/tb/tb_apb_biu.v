/*
 * Copyright (c) 2020 The VxEngine Project. All rights reserved.
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
 * Testbench for APB bus interface unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_apb_biu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */
	localparam ADDR_WIDTH = 32;
	localparam DATA_WIDTH = 32;

	reg			clk;
	reg			nrst;
	/* APB interface */
	reg [ADDR_WIDTH-1:0]	apb_paddr;
	reg			apb_psel;
	reg			apb_penable;
	reg			apb_pwrite;
	reg [DATA_WIDTH-1:0]	apb_pwdata;
	wire [DATA_WIDTH-1:0]	apb_prdata;
	wire			apb_pready;
	/* BIU interface */
	wire [ADDR_WIDTH-1:0]	biu_addr;
	wire			biu_enable;
	wire			biu_rnw;
	wire [DATA_WIDTH-1:0]	biu_wdata;
	wire [DATA_WIDTH-1:0]	biu_rdata;
	wire			biu_accept;


	always
		#HCLK clk = !clk;


	/* APB read */
	task apb_read;
	input [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge clk)
		begin
			apb_paddr <= addr;
			apb_psel <= 1'b1;
			apb_penable <= 1'b0;
			apb_pwrite <= 1'b0;
		end

		@(posedge clk)
		begin
			apb_penable <= 1'b1;
		end

		@(posedge clk);

		@(posedge clk)
		begin
			apb_psel <= 1'b0;
			apb_penable <= 1'b0;
		end
	end
	endtask


	/* APB write */
	task apb_write;
	input [ADDR_WIDTH-1:0] addr;
	input [DATA_WIDTH-1:0] data;
	begin
		@(posedge clk)
		begin
			apb_paddr <= addr;
			apb_psel <= 1'b1;
			apb_penable <= 1'b0;
			apb_pwrite <= 1'b1;
			apb_pwdata <= data;
		end

		@(posedge clk)
		begin
			apb_penable <= 1'b1;
		end

		@(posedge clk);

		@(posedge clk)
		begin
			apb_psel <= 1'b0;
			apb_penable <= 1'b0;
		end
	end
	endtask


	task wait_pos_clk;
		@(posedge clk);
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_apb_biu);

		clk = 1;
		nrst = 0;

		apb_paddr = 32'h0000_0000;
		apb_psel = 1'b0;
		apb_penable = 1'b0;
		apb_pwrite = 1'b0;
		apb_pwdata = 32'h0000_0000;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();

		apb_read(32'h0000_000c);

		wait_pos_clk();
		wait_pos_clk();

		apb_write(32'h0000_000c, 32'hf1f2_f3f4);

		wait_pos_clk();
		wait_pos_clk();

		#500 $finish;
	end


	/* APB BIU instance */
	apb_biu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) biu (
		.clk(clk),
		.nrst(nrst),
		/* APB interface */
		.apb_paddr(apb_paddr),
		.apb_psel(apb_psel),
		.apb_penable(apb_penable),
		.apb_pwrite(apb_pwrite),
		.apb_pwdata(apb_pwdata),
		.apb_prdata(apb_prdata),
		.apb_pready(apb_pready),
		/* BIU interface */
		.biu_addr(biu_addr),
		.biu_enable(biu_enable),
		.biu_rnw(biu_rnw),
		.biu_wdata(biu_wdata),
		.biu_rdata(biu_rdata),
		.biu_accept(biu_accept)
);

assign biu_rdata = 32'hfefe_fafa;
assign biu_accept = 1'b1;


endmodule /* tb_apb_biu */
