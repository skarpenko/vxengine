/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * VxE CU interrupts and faults unit
 */


/* Interrupts and faults */
module vxe_cu_intr_flt_unit(
	clk,
	nrst,
	/* External interrupts and faults interface */
	o_intr_vld,
	o_intr,
	o_last_instr_addr,
	o_last_instr_data,
	o_vpu_fault,
	/* Internal CU interface */
	i_send_intr,
	i_complete,
	i_flt_fetch,
	i_flt_fetch_addr,
	i_flt_decode,
	i_flt_decode_addr,
	i_flt_decode_data,
	i_flt_vpu

);
parameter VPUS_NR = 2;		/* Number of VPUs */
`include "vxe_intr_params.vh"
/* Global signals */
input wire			clk;
input wire			nrst;
/* External interrupts and faults interface */
output reg			o_intr_vld;
output wire [3:0]		o_intr;
output wire [36:0]		o_last_instr_addr;
output wire [63:0]		o_last_instr_data;
output wire [VPUS_NR-1:0]	o_vpu_fault;
/* Internal CU interface */
input wire			i_send_intr;
input wire			i_complete;
input wire			i_flt_fetch;
input wire [36:0]		i_flt_fetch_addr;
input wire			i_flt_decode;
input wire [36:0]		i_flt_decode_addr;
input wire [63:0]		i_flt_decode_data;
input wire [VPUS_NR-1:0]	i_flt_vpu;


assign	o_intr = intr;
assign	o_last_instr_addr = last_instr_addr;
assign	o_last_instr_data = last_instr_data;
assign	o_vpu_fault = vpu_fault;


/* Internal registers */
reg [3:0]		intr;
reg [36:0]		last_instr_addr;
reg [63:0]		last_instr_data;
reg [VPUS_NR-1:0]	vpu_fault;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		o_intr_vld <= 1'b0;
		intr <= 4'h0;
		vpu_fault <= {VPUS_NR{1'b0}};
	end
	else
	begin
		o_intr_vld <= 1'b0;

		/* Clear state if interrupt was fired */
		if(o_intr_vld)
			intr <= 4'h0;

		/* Completion interrupt */
		if(i_complete)
			intr[INTR_IDX_COMPLETED] <= 1'b1;

		/* Data load fault */
		if(|i_flt_vpu)
		begin
			vpu_fault <= vpu_fault | i_flt_vpu;
			intr[INTR_IDX_ERR_DATA] <= 1'b1;
		end

		/* Instruction fetch or decode fault */
		if(i_flt_fetch && i_flt_decode)
		begin
			intr[INTR_IDX_ERR_FETCH] <= 1'b1;
			intr[INTR_IDX_ERR_INSTR] <= 1'b1;
			last_instr_addr <= i_flt_decode_addr;
			last_instr_data <= i_flt_decode_data;
		end
		else if(i_flt_fetch)
		begin
			intr[INTR_IDX_ERR_FETCH] <= 1'b1;
			if(!intr[INTR_IDX_ERR_INSTR])
				last_instr_addr <= i_flt_fetch_addr;
		end
		else if(i_flt_decode)
		begin
			intr[INTR_IDX_ERR_INSTR] <= 1'b1;
			last_instr_addr <= i_flt_decode_addr;
			last_instr_data <= i_flt_decode_data;
		end

		/* Sent interrupt to interrupt controller */
		if(i_send_intr)
			o_intr_vld <= 1'b1;
	end
end


endmodule /* vxe_cu_intr_flt_unit */
