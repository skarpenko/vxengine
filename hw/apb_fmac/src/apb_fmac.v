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
 * APB FMAC
 *
 * Register map:
 *   0x00    r/w    Accumulator
 *   0x04    r/w    Multiplicand
 *   0x08    r/w    Multiplier
 *   0x0c    r/o    Result
 *   0x10    r/o    Result flags
 *       bit  0: Infinity
 *       bit  1: NaN
 *       bit  2: Zero
 *       bit  3: Sign
 *       bit 31: Result register is valid
 *   0x14    r/w    Write starts operation; read returns magic value
 */

module apb_fmac(
	clk,
	nrst,
	/* APB interface */
	apb_paddr,
	apb_psel,
	apb_penable,
	apb_pwrite,
	apb_pwdata,
	apb_prdata,
	apb_pready
);
input wire		clk;
input wire		nrst;
/* APB interface */
input wire [4:0]	apb_paddr;
input wire		apb_psel;
input wire		apb_penable;
input wire		apb_pwrite;
input wire [31:0]	apb_pwdata;
output wire [31:0]	apb_prdata;
output wire		apb_pready;


/* Registers */
reg [31:0]	reg_a;	/* Accumulator operand */
reg [31:0]	reg_b;	/* Multiplicand */
reg [31:0]	reg_c;	/* Multiplier */
reg [31:0]	reg_r;	/* Result */
reg		reg_v;	/* Result valid flag */
reg [3:0]	reg_fl;	/* Result flags */
reg		enable;	/* Enable MAC */


/* BIU wires */
wire [4:0]	biu_addr;
wire		biu_enable;
wire		biu_rnw;
wire [31:0]	biu_wdata;
reg [31:0]	biu_rdata;


/* Register read logic */
always @(*)
begin
	if(biu_enable && biu_rnw)
	begin
		case(biu_addr[4:2])
		3'd00: biu_rdata	= reg_a;
		3'd01: biu_rdata	= reg_b;
		3'd02: biu_rdata	= reg_c;
		3'd03: biu_rdata	= reg_r;
		3'd04: biu_rdata	= { reg_v, 27'b0, reg_fl };
		3'd05: biu_rdata	= 32'hFEFE_FAFA;	/* Magic */
		default: biu_rdata	= 32'hDEAD_BEEF;
		endcase;
	end
	else
		biu_rdata = 32'hDEAD_BEEF;
end


/* Register write logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		enable <= 1'b0;
	end
	else if(biu_enable && !biu_rnw)
	begin
		case(biu_addr[4:2])
		3'd00: reg_a <= biu_wdata;
		3'd01: reg_b <= biu_wdata;
		3'd02: reg_c <= biu_wdata;
		3'd05: enable <= 1'b1;
		default: ;
		endcase;
	end
	else
		enable <= 1'b0;
end


/* APB bus interface */
apb_biu #(
	.ADDR_WIDTH(5),
	.DATA_WIDTH(32)
) apb_biu0 (
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
	.biu_accept(1'b1)
);


/* Five-stage FMAC32 wires */
wire [31:0]	mac_p;
wire		mac_sign;
wire		mac_zero;
wire		mac_nan;
wire		mac_inf;
wire		mac_valid;


/* Result store logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		reg_v <= 1'b0;
	end
	else
	begin
		if(mac_valid)
		begin
			reg_r <= mac_p;
			reg_v <= mac_valid;
			reg_fl <= { mac_sign, mac_zero, mac_nan, mac_inf };
		end

		/* Reset valid state if new operation has started */
		if(enable)
			reg_v <= 1'b0;
	end
end


/* FMAC unit */
flp32_mac_5stg fmac(
	.clk(clk),
	.nrst(nrst),
	/* Input operands */
	.i_a(reg_a),
	.i_b(reg_b),
	.i_c(reg_c),
	.i_valid(enable),
	/* Result */
	.o_p(mac_p),
	.o_sign(mac_sign),
	.o_zero(mac_zero),
	.o_nan(mac_nan),
	.o_inf(mac_inf),
	.o_valid(mac_valid)
);


endmodule /* apb_fmac */
