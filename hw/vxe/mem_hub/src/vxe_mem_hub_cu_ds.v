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
 * VxE CU downstream traffic control
 */


/* CU downstream */
module vxe_mem_hub_cu_ds(
	clk,
	nrst,
	/* Master select */
	i_m_sel,
	/* Outgoing response */
	i_rss_rdy,
	o_rss,
	o_rss_wr,
	i_rsd_rdy,
	o_rsd,
	o_rsd_wr,
	/* Incoming response on Master 0 */
	i_m0_rss_vld,
	i_m0_rss,
	o_m0_rss_rd,
	i_m0_rsd_vld,
	i_m0_rsd,
	o_m0_rsd_rd,
	/* Incoming response on Master 1 */
	i_m1_rss_vld,
	i_m1_rss,
	o_m1_rss_rd,
	i_m1_rsd_vld,
	i_m1_rsd,
	o_m1_rsd_rd
);
/* FSM states */
localparam [1:0]	FSM_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RDXX = 2'b01;	/* Read source */
localparam [1:0]	FSM_XXWR = 2'b10;	/* Write destination */
localparam [1:0]	FSM_RDWR = 2'b11;	/* Read and write */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Master select */
input wire		i_m_sel;
/* Outgoing response */
input wire		i_rss_rdy;
output reg [8:0]	o_rss;
output reg		o_rss_wr;
input wire		i_rsd_rdy;
output reg [63:0]	o_rsd;
output reg		o_rsd_wr;
/* Incoming response on Master 0 */
input wire		i_m0_rss_vld;
input wire [8:0]	i_m0_rss;
output wire		o_m0_rss_rd;
input wire		i_m0_rsd_vld;
input wire [63:0]	i_m0_rsd;
output wire		o_m0_rsd_rd;
/* Incoming response on Master 1 */
input wire		i_m1_rss_vld;
input wire [8:0]	i_m1_rss;
output wire		o_m1_rss_rd;
input wire		i_m1_rsd_vld;
input wire [63:0]	i_m1_rsd;
output wire		o_m1_rsd_rd;


wire		m_rss_vld;
wire [8:0]	m_rss;	/* Resp. status: { 6b: CID, 1b: RnW, 2b: Error } */
reg		m_rss_rd;

wire		m_rsd_vld;
wire [63:0]	m_rsd;	/* Resp. data */
reg		m_rsd_rd;


assign m_rss_vld	= (i_m_sel == 1'b0) ? i_m0_rss_vld : i_m1_rss_vld;
assign m_rss		= (i_m_sel == 1'b0) ? i_m0_rss : i_m1_rss;
assign o_m0_rss_rd	= (i_m_sel == 1'b0) ? m_rss_rd : 1'b0;
assign o_m1_rss_rd	= (i_m_sel == 1'b1) ? m_rss_rd : 1'b0;

assign m_rsd_vld	= (i_m_sel == 1'b0) ? i_m0_rsd_vld : i_m1_rsd_vld;
assign m_rsd		= (i_m_sel == 1'b0) ? i_m0_rsd : i_m1_rsd;
assign o_m0_rsd_rd	= (i_m_sel == 1'b0) ? m_rsd_rd : 1'b0;
assign o_m1_rsd_rd	= (i_m_sel == 1'b1) ? m_rsd_rd : 1'b0;


/** Response status **/
reg [1:0]	s_fsm_state;
reg [8:0]	s_stash_q;	/* Temporary storage for status */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		s_fsm_state <= FSM_IDLE;
		m_rss_rd <= 1'b0;
 		o_rss_wr <= 1'b0;
	end
	else
	begin
		case(s_fsm_state)
		FSM_RDXX: begin
			if(m_rss_vld)
			begin
				o_rss <= m_rss;
				o_rss_wr <= 1'b1;
				s_fsm_state <= FSM_RDWR;
			end
		end
		FSM_XXWR: begin
			if(i_rss_rdy)
			begin
				o_rss <= s_stash_q;
				m_rss_rd <= 1'b1;
				s_fsm_state <= FSM_RDWR;
			end
		end
		FSM_RDWR: begin
			if(m_rss_vld && i_rss_rdy)
			begin
				o_rss <= m_rss;
			end
			else if(m_rss_vld && !i_rss_rdy)
			begin
				s_stash_q <= m_rss;
				m_rss_rd <= 1'b0;
				s_fsm_state <= FSM_XXWR;
			end
			else if(!m_rss_vld && i_rss_rdy)
			begin
				o_rss_wr <= 1'b0;
				s_fsm_state <= FSM_RDXX;
			end
		end
		default: begin
			m_rss_rd <= 1'b1;
			s_fsm_state <= FSM_RDXX;
		end
		endcase
	end
end


/** Response data **/
reg [1:0]	d_fsm_state;
reg [63:0]	d_stash_q;	/* Temporary storage for data */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		d_fsm_state <= FSM_IDLE;
		m_rsd_rd <= 1'b0;
 		o_rsd_wr <= 1'b0;
	end
	else
	begin
		case(d_fsm_state)
		FSM_RDXX: begin
			if(m_rsd_vld)
			begin
				o_rsd <= m_rsd;
				o_rsd_wr <= 1'b1;
				d_fsm_state <= FSM_RDWR;
			end
		end
		FSM_XXWR: begin
			if(i_rsd_rdy)
			begin
				o_rsd <= d_stash_q;
				m_rsd_rd <= 1'b1;
				d_fsm_state <= FSM_RDWR;
			end
		end
		FSM_RDWR: begin
			if(m_rsd_vld && i_rsd_rdy)
			begin
				o_rsd <= m_rsd;
			end
			else if(m_rsd_vld && !i_rsd_rdy)
			begin
				d_stash_q <= m_rsd;
				m_rsd_rd <= 1'b0;
				d_fsm_state <= FSM_XXWR;
			end
			else if(!m_rsd_vld && i_rsd_rdy)
			begin
				o_rsd_wr <= 1'b0;
				d_fsm_state <= FSM_RDXX;
			end
		end
		default: begin
			m_rsd_rd <= 1'b1;
			d_fsm_state <= FSM_RDXX;
		end
		endcase
	end
end


endmodule /* vxe_mem_hub_cu_ds */
