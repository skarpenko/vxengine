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


/* APB logic */
always @(*)
begin
	if(apb_psel && apb_penable)
	begin
		biu_addr = apb_paddr;
		biu_enable = 1'b1;
		biu_rnw = ~apb_pwrite;
		biu_wdata = apb_pwdata;
		apb_pready = biu_accept;
		apb_prdata = biu_rdata;
	end
	else
	begin
		biu_addr = apb_paddr;
		biu_enable = 1'b0;
		biu_rnw = ~apb_pwrite;
		biu_wdata = apb_pwdata;
		apb_pready = biu_accept;
		apb_prdata = biu_rdata;
	end
end


endmodule /* apb_biu */
