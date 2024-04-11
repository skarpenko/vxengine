/*
 * Copyright (c) 2020-2024 The VxEngine Project. All rights reserved.
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
 * VxE VPU vector address generator unit
 */


/* Address generator unit */
module vxe_vpu_prod_eu_agen(
	clk,
	nrst,
	/* Vector base and length */
	i_vaddr,
	i_vlen,
	/* Control interface */
	i_latch,
	i_incr,
	/* Generated address and word enable mask */
	o_valid,
	o_addr,
	o_we_mask
);
/* Global signals */
input wire		clk;
input wire		nrst;
/* Vector base and length */
input wire [37:0]	i_vaddr;
input wire [19:0]	i_vlen;
/* Control interface */
input wire		i_latch;
input wire		i_incr;
/* Generated address and word enable mask */
output wire		o_valid;
output wire [36:0]	o_addr;
output wire [1:0]	o_we_mask;


/* Internal storage */
reg [37:0]	q_vaddr;
reg [19:0]	q_vlen;

wire [1:0]	c_we_mask = ~q_vaddr[0] ?
			(q_vlen == 20'h00001 ? 2'b01 : 2'b11) : 2'b10;
wire		c_valid = |q_vlen;


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		q_vlen <= 20'h00000;
	end
	else if(i_incr && c_valid)
	begin
		if(q_vaddr[0])			/* Address is not two words aligned. */
		begin
			q_vaddr <= q_vaddr + 2'h1;
			q_vlen <= q_vlen - 2'h1;
		end
		else if(q_vlen == 20'h00001)	/* Only one word remaining. */
		begin
			q_vlen <= q_vlen - 2'h1;
		end
		else				/* Can load two words at a time. */
		begin
			q_vaddr <= q_vaddr + 2'h2;
			q_vlen <= q_vlen - 2'h2;
		end

	end
	else if(i_latch)
	begin
		q_vaddr <= i_vaddr;
		q_vlen <= i_vlen;
	end
end


assign o_valid = c_valid;
assign o_addr = q_vaddr[37:1];
assign o_we_mask = c_we_mask;


endmodule /* vxe_vpu_prod_eu_agen */
