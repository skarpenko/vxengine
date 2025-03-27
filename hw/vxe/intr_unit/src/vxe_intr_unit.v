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
 * Interrupt control unit
 */


/* Interrupt unit */
module vxe_intr_unit #(
	parameter NR_INT = 4	/* Number of interrupts */
)
(
	clk,
	nrst,
	/* CU interface signals */
	i_cu_intr_vld,
	i_cu_intr,
	/* RegIO interface signals */
	i_rio_mask,
	o_rio_raw,
	o_rio_active,
	i_rio_ack_en,
	i_rio_ack,
	/* Interrupt line */
	o_intr
);
/* Global signals */
input wire			clk;
input wire			nrst;
/* CU interface signals */
input wire			i_cu_intr_vld;
input wire [NR_INT-1:0]		i_cu_intr;
/* RegIO interface signals */
input wire [NR_INT-1:0]		i_rio_mask;
output wire [NR_INT-1:0]	o_rio_raw;
output wire [NR_INT-1:0]	o_rio_active;
input wire			i_rio_ack_en;
input wire [NR_INT-1:0]		i_rio_ack;
/* Interrupt line */
output wire			o_intr;


assign o_intr = |o_rio_active;
assign o_rio_raw = raw_q;
assign o_rio_active = raw_q & ~i_rio_mask;


reg [NR_INT-1:0]	raw_q;	/* Registered interrupts */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		raw_q <= {NR_INT{1'b0}};
	end
	else
	begin
		if(i_rio_ack_en && i_cu_intr_vld)
			raw_q <= (raw_q & ~i_rio_ack) | i_cu_intr;
		else if(i_cu_intr_vld)
			raw_q <= raw_q | i_cu_intr;
		else if(i_rio_ack_en)
			raw_q <= raw_q & ~i_rio_ack;
	end
end


endmodule /* vxe_intr_unit */
