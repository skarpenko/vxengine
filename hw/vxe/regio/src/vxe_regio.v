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
 * Register I/O
 */


/* RegIO */
module vxe_regio(
	clk,
	nrst,
	/* Bus interface signals */
	i_wreg_idx,
	i_wdata,
	i_wenable,
	o_waccept,
	o_werror,
	i_rreg_idx,
	o_rdata,
	i_renable,
	o_raccept,
	o_rerror,
	/* CU interface signals */
	i_cu_busy,
	i_cu_last_instr_addr,
	i_cu_last_instr_data,
	o_cu_pgm_addr,
	o_cu_start,
	/* Interrupt unit interface signals */
	i_intu_raw,
	i_intu_act,
	o_intu_msk,
	o_intu_ack_vld,
	o_intu_ack,
	/* Memory hub interface signals */
	o_cu_mas_sel
);
`include "vxe_regio_params.vh"
input wire		clk;
input wire		nrst;
/* Bus interface - write register */
input wire [9:0]	i_wreg_idx;
input wire [31:0]	i_wdata;
input wire		i_wenable;
output wire		o_waccept;
output wire		o_werror;
/* Bus interface - read register */
input wire [9:0]	i_rreg_idx;
output reg [31:0]	o_rdata;
input wire		i_renable;
output wire		o_raccept;
output wire		o_rerror;
/* CU interface */
input wire 		i_cu_busy;
input wire [36:0]	i_cu_last_instr_addr;
input wire [63:0]	i_cu_last_instr_data;
output wire [36:0]	o_cu_pgm_addr;
output reg		o_cu_start;
/* Interrupt unit interface */
input wire [3:0]	i_intu_raw;
input wire [3:0]	i_intu_act;
output wire [3:0]	o_intu_msk;
output reg		o_intu_ack_vld;
output reg [3:0]	o_intu_ack;
output wire		o_cu_mas_sel;


/* Always ready to accept and returns no error */
assign o_waccept = 1'b1;
assign o_werror = 1'b0;
assign o_raccept = 1'b1;
assign o_rerror = 1'b0;


/* Internal wires and registers for reg I/O */
reg [36:0]	reg_pgm_addr;
reg [3:0]	reg_intr_mask;
reg		reg_cu_mas_sel;

assign o_cu_pgm_addr = reg_pgm_addr;
assign o_intu_msk = reg_intr_mask;
assign o_cu_mas_sel = reg_cu_mas_sel;


/* Register write logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		o_cu_start <= 1'b0;
		o_intu_ack_vld <= 1'b0;
		reg_pgm_addr <= 37'b0;
		reg_intr_mask <= 4'b0;
		reg_cu_mas_sel <= 1'b0;
	end
	else
	begin
		o_cu_start <= 1'b0;
		o_intu_ack_vld <= 1'b0;
		if(i_wenable)
		begin
			case(i_wreg_idx)
			REG_CTRL:		reg_cu_mas_sel <= i_wdata[0];
			REG_INTR_ACT: begin
				o_intu_ack <= i_wdata[3:0];
				o_intu_ack_vld <= 1'b1;
			end
			REG_INTR_MSK:		reg_intr_mask <= i_wdata[3:0];
			REG_PGM_ADDR_LO:	reg_pgm_addr[28:0] <= i_wdata[31:3];
			REG_PGM_ADDR_HI:	reg_pgm_addr[36:29] <= i_wdata[7:0];
			REG_START:		o_cu_start <= ~i_cu_busy;
			default: ;
		endcase;
		end
	end
end


/* Register read logic */
always @(*)
begin
	o_rdata = 32'hdead_beef;
	if(i_renable)
	begin
		case(i_rreg_idx)
		REG_ID:				o_rdata = VXENGINE_ID;
		REG_CTRL:			o_rdata = { 31'h0, reg_cu_mas_sel };
		REG_STATUS:			o_rdata = { 31'h0, i_cu_busy};
		REG_INTR_ACT:			o_rdata = { 28'h0, i_intu_act };
		REG_INTR_MSK:			o_rdata = { 28'h0, reg_intr_mask };
		REG_INTR_RAW:			o_rdata = { 28'h0, i_intu_raw };
		REG_PGM_ADDR_LO:		o_rdata = { reg_pgm_addr[28:0], 3'b000 };
		REG_PGM_ADDR_HI:		o_rdata = { 24'h0, reg_pgm_addr[36:29] };
		REG_START:			o_rdata = 32'hffff_ffff;	/* Write only register */
		REG_FAULT_INSTR_ADDR_LO:	o_rdata = { i_cu_last_instr_addr[28:0], 3'b000 };
		REG_FAULT_INSTR_ADDR_HI:	o_rdata = { 24'h0, i_cu_last_instr_addr[36:29] };
		REG_FAULT_INSTR_LO:		o_rdata = i_cu_last_instr_data[31:0];
		REG_FAULT_INSTR_HI:		o_rdata = i_cu_last_instr_data[63:32];
		default:			o_rdata = 32'hdead_beef;
		endcase;
	end
end


endmodule /* vxe_regio */
