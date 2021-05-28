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
 * VxE CU upstream traffic control
 */


/* CU upstream */
module vxe_mem_hub_cu_us(
	clk,
	nrst,
	/* Master select */
	i_m_sel,
	/* Incoming request */
	i_rqa_vld,
	i_rqa,
	o_rqa_rd,
	/* Route to Master 0 */
	i_m0_rqa_rdy,
	o_m0_rqa,
	o_m0_rqa_wr,
	/* Route to Master 1 */
	i_m1_rqa_rdy,
	o_m1_rqa,
	o_m1_rqa_wr
);
/* FSM states */
localparam [1:0]	FSM_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RDXX = 2'b10;	/* Read source */
localparam [1:0]	FSM_XXWR = 2'b01;	/* Write destination */
localparam [1:0]	FSM_RDWR = 2'b11;	/* Read and write */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Master select */
input wire		i_m_sel;
/* Incoming request */
input wire		i_rqa_vld;
input wire [43:0]	i_rqa;
output reg		o_rqa_rd;
/* Route to Master 0 */
input wire		i_m0_rqa_rdy;
output wire [43:0]	o_m0_rqa;
output wire		o_m0_rqa_wr;
/* Route to Master 1 */
input wire		i_m1_rqa_rdy;
output wire [43:0]	o_m1_rqa;
output wire		o_m1_rqa_wr;


reg [43:0]	m_rqa;	/* Req data: { 6b: CID, 1b: RnW, 37b: Addr[40:3] } */
reg		m_rqa_wr;
wire		m_rqa_rdy;

assign m_rqa_rdy	= (i_m_sel == 1'b0) ? i_m0_rqa_rdy : i_m1_rqa_rdy;
assign o_m0_rqa		= (i_m_sel == 1'b0) ? m_rqa : o_m0_rqa;
assign o_m0_rqa_wr	= (i_m_sel == 1'b0) ? m_rqa_wr : 1'b0;
assign o_m1_rqa		= (i_m_sel == 1'b1) ? m_rqa : o_m1_rqa;
assign o_m1_rqa_wr	= (i_m_sel == 1'b1) ? m_rqa_wr : 1'b0;


reg [1:0]	fsm_state;
reg [43:0]	stash_q;	/* Temporary storage */


always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_state <= FSM_IDLE;
		m_rqa_wr <= 1'b0;
 		o_rqa_rd <= 1'b0;
	end
	else
	begin
		case(fsm_state)
		FSM_RDXX: begin
			if(i_rqa_vld)
			begin
				m_rqa <= i_rqa;
				m_rqa_wr <= 1'b1;
				fsm_state <= FSM_RDWR;
			end
		end
		FSM_XXWR: begin
			if(m_rqa_rdy)
			begin
				m_rqa <= stash_q;
				o_rqa_rd <= 1'b1;
				fsm_state <= FSM_RDWR;
			end
		end
		FSM_RDWR: begin
			if(i_rqa_vld && m_rqa_rdy)
			begin
				m_rqa <= i_rqa;
			end
			else if(i_rqa_vld && !m_rqa_rdy)
			begin
				stash_q <= i_rqa;
				o_rqa_rd <= 1'b0;
				fsm_state <= FSM_XXWR;
			end
			else if(!i_rqa_vld && m_rqa_rdy)
			begin
				m_rqa_wr <= 1'b0;
				fsm_state <= FSM_RDXX;
			end
		end
		default: begin
			o_rqa_rd <= 1'b1;
			fsm_state <= FSM_RDXX;
		end
		endcase
	end
end


endmodule /* vxe_mem_hub_cu_us */
