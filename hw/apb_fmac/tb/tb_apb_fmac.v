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
 * Testbench for APB FMAC
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_apb_fmac();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* APB interface */
	reg [4:0]	apb_paddr;
	reg		apb_psel;
	reg		apb_penable;
	reg		apb_pwrite;
	reg [31:0]	apb_pwdata;
	wire [31:0]	apb_prdata;
	wire		apb_pready;


	always
		#HCLK clk = !clk;


	/* APB read */
	task apb_read;
	input [4:0] addr;
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

		@(posedge clk)
		begin
			apb_psel <= 1'b0;
			apb_penable <= 1'b0;
		end
	end
	endtask


	/* APB write */
	task apb_write;
	input [4:0] addr;
	input [31:0] data;
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
		$dumpvars(0, tb_apb_fmac);

		clk = 1;
		nrst = 0;

		apb_paddr = 5'h00;
		apb_psel = 1'b0;
		apb_penable = 1'b0;
		apb_pwrite = 1'b0;
		apb_pwdata = 32'h0000_0000;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();

		apb_read(5'h14);

		wait_pos_clk();
		wait_pos_clk();

		apb_write(5'h00, 32'h401a_3237);

		wait_pos_clk();
		wait_pos_clk();

		apb_write(5'h04, 32'h3eae_76d1);

		wait_pos_clk();
		wait_pos_clk();

		apb_write(5'h08, 32'h3ee9_c749);

		wait_pos_clk();
		wait_pos_clk();

		apb_write(5'h14, 32'h0);

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		apb_read(5'h0c);

		wait_pos_clk();
		wait_pos_clk();


		#500 $finish;
	end


	/* APB FMAC instance */
	apb_fmac fmac(
		.clk(clk),
		.nrst(nrst),
		/* APB interface */
		.apb_paddr(apb_paddr),
		.apb_psel(apb_psel),
		.apb_penable(apb_penable),
		.apb_pwrite(apb_pwrite),
		.apb_pwdata(apb_pwdata),
		.apb_prdata(apb_prdata),
		.apb_pready(apb_pready)
	);


endmodule /* tb_apb_fmac */
