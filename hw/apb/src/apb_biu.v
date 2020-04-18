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
 * APB bus interface unit
 */

module apb_biu
#(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
)
(
	clk,
	nrst,
	/* APB interface */
	apb_paddr,
	apb_psel,
	apb_penable,
	apb_pwrite,
	apb_pwdata,
	apb_prdata,
	apb_pready,
	/* BIU interface */
	biu_addr,
	biu_enable,
	biu_rnw,
	biu_wdata,
	biu_rdata,
	biu_accept
);
localparam APB_SETUP		= 1'b0;	/* APB FSM Setup phase */
localparam APB_ENABLE		= 1'b1;	/* APB FSM Enable phase */
/****/
input wire			clk;
input wire			nrst;
/* APB interface */
input wire [ADDR_WIDTH-1:0]	apb_paddr;
input wire			apb_psel;
input wire			apb_penable;
input wire			apb_pwrite;
input wire [DATA_WIDTH-1:0]	apb_pwdata;
output reg [DATA_WIDTH-1:0]	apb_prdata;
output reg			apb_pready;
/* BIU interface */
output reg [ADDR_WIDTH-1:0]	biu_addr;
output reg			biu_enable;
output reg			biu_rnw;
output reg [DATA_WIDTH-1:0]	biu_wdata;
input wire [DATA_WIDTH-1:0]	biu_rdata;
input wire			biu_accept;


/* APB FSM state */
reg apb_state;


/* APB FSM */
always @(posedge clk or negedge nrst)
begin : apb_fsm
	if(!nrst)
	begin
		apb_pready <= 1'b0;
		biu_enable <= 1'b0;
		apb_state <= APB_SETUP;
	end
	else if(apb_state == APB_SETUP)
	begin
		apb_pready <= 1'b0;
		biu_enable <= 1'b0;

		if(apb_psel && apb_penable)
		begin
			apb_state <= APB_ENABLE;
			biu_addr <= apb_paddr;
			biu_enable <= 1'b1;
			biu_rnw <= ~apb_pwrite;
			biu_wdata <= apb_pwdata;
		end
	end
	else if(apb_psel && apb_penable && apb_state == APB_ENABLE)
	begin
			apb_pready <= biu_accept;
			apb_state <= biu_accept ? APB_SETUP : apb_state;
			apb_prdata <= biu_rdata;
	end
	else
		apb_state <= APB_SETUP;
end


endmodule /* apb_biu */
