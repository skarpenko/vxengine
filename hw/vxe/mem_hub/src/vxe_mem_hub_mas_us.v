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
 * VxE master port upstream traffic control
 */


/* Master port upstream */
module vxe_mem_hub_mas_us(
	clk,
	nrst,
	/* Incoming request from CU */
	i_cu_rqa_vld,
	i_cu_rqa,
	o_cu_rqa_rd,
	/* Incoming request from VPU0 */
	i_vpu0_rqa_vld,
	i_vpu0_rqa,
	o_vpu0_rqa_rd,
	i_vpu0_rqd_vld,
	i_vpu0_rqd,
	o_vpu0_rqd_rd,
	/* Incoming request from VPU1 */
	i_vpu1_rqa_vld,
	i_vpu1_rqa,
	o_vpu1_rqa_rd,
	i_vpu1_rqd_vld,
	i_vpu1_rqd,
	o_vpu1_rqd_rd,
	/* Outgoing request to master port */
	i_m_rqa_rdy,
	o_m_rqa,
	o_m_rqa_wr,
	i_m_rqd_rdy,
	o_m_rqd,
	o_m_rqd_wr
);
/* Rx FSM states */
localparam [2:0]	FSM_RX_IDLE = 3'b000;	/* Idle */
localparam [2:0]	FSM_RX_RDCU = 3'b001;	/* Read requests from CU */
localparam [2:0]	FSM_RX_RDV0 = 3'b010;	/* Read requests from VPU0 */
localparam [2:0]	FSM_RX_RDV1 = 3'b011;	/* Read requests from VPU1 */
localparam [2:0]	FSM_RX_STLL = 3'b111;	/* Stall state */
/* Tx FSM states */
localparam		FSM_TX_IDLE = 1'b0;	/* Idle */
localparam		FSM_TX_SEND = 1'b1;	/* Send to master port  */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Incoming request from CU */
input wire		i_cu_rqa_vld;
input wire [43:0]	i_cu_rqa;
output reg		o_cu_rqa_rd;
/* Incoming request from VPU0 */
input wire		i_vpu0_rqa_vld;
input wire [43:0]	i_vpu0_rqa;
output reg		o_vpu0_rqa_rd;
input wire		i_vpu0_rqd_vld;
input wire [71:0]	i_vpu0_rqd;
output reg		o_vpu0_rqd_rd;
/* Incoming request from VPU1 */
input wire		i_vpu1_rqa_vld;
input wire [43:0]	i_vpu1_rqa;
output reg		o_vpu1_rqa_rd;
input wire		i_vpu1_rqd_vld;
input wire [71:0]	i_vpu1_rqd;
output reg		o_vpu1_rqd_rd;
/* Outgoing request to master port */
input wire		i_m_rqa_rdy;
output reg [43:0]	o_m_rqa;
output reg		o_m_rqa_wr;
input wire		i_m_rqd_rdy;
output reg [71:0]	o_m_rqd;
output reg		o_m_rqd_wr;


/*
 * Requests scheduling transition scheme to avoid client starvation
 *
 * Current State    Next State 1    Next State 2
 *  RDCU     -->     RDV0            RDV1
 *  RDV0     -->     RDV1            RDCU
 *  RDV1     -->     RDCU            RDV0
 *
 * Next state is selected based on client readiness, readiness is checked
 * in order specified above.
 */



/* Address FIFO */
reg [43:0]	m_rqa_fifo[0:3];	/* Incoming request address FIFO */
reg [2:0]	m_rqa_fifo_rp;		/* Read pointer */
reg [2:0]	m_rqa_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	m_rqa_fifo_pre_rp = m_rqa_fifo_rp - 1'b1;
/* FIFO states */
wire m_rqa_fifo_empty = (m_rqa_fifo_rp[1:0] == m_rqa_fifo_wp[1:0]) &&
	(m_rqa_fifo_rp[2] == m_rqa_fifo_wp[2]);
wire m_rqa_fifo_full = (m_rqa_fifo_rp[1:0] == m_rqa_fifo_wp[1:0]) &&
	(m_rqa_fifo_rp[2] != m_rqa_fifo_wp[2]);
wire m_rqa_fifo_pre_full = (m_rqa_fifo_pre_rp[1:0] == m_rqa_fifo_wp[1:0]) &&
	(m_rqa_fifo_pre_rp[2] != m_rqa_fifo_wp[2]);


/* Data FIFO */
reg [71:0]	m_rqd_fifo[0:3];	/* Incoming request data FIFO */
reg [2:0]	m_rqd_fifo_rp;		/* Read pointer */
reg [2:0]	m_rqd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire m_rqd_fifo_empty = (m_rqd_fifo_rp[1:0] == m_rqd_fifo_wp[1:0]) &&
	(m_rqd_fifo_rp[2] == m_rqd_fifo_wp[2]);


/* Outgoing FIFO stall */
wire fifo_stall = m_rqa_fifo_full || m_rqa_fifo_pre_full;


/* Decoded request from VPU0 */
wire [5:0]	rqav0_txnid;		/* Transaction Id */
wire		rqav0_rnw;		/* Read or Write transaction */
wire [36:0]	rqav0_addr;		/* Upper 37-bits of 40-bit address */


/* Decoded request from VPU1 */
wire [5:0]	rqav1_txnid;		/* Transaction Id */
wire		rqav1_rnw;		/* Read or Write transaction */
wire [36:0]	rqav1_addr;		/* Upper 37-bits of 40-bit address */


/* VPU0 data hold register */
reg [71:0]	v0_data_hold_r;		/* Stored data */
reg		v0_data_hold_vld;	/* Register valid flag */


/* VPU1 data hold register */
reg [71:0]	v1_data_hold_r;		/* Stored data */
reg		v1_data_hold_vld;	/* Register valid flag */



/* RX FSM state */
reg [2:0]	rx_fsm;
reg [2:0]	stall_s;	/* State when stall was detected */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rx_fsm <= FSM_RX_IDLE;
		v0_data_hold_vld <= 1'b0;
		v1_data_hold_vld <= 1'b0;
		m_rqa_fifo_wp <= 3'b000;
		m_rqd_fifo_wp <= 3'b000;
		o_cu_rqa_rd <= 1'b0;
		o_vpu0_rqa_rd <= 1'b0;
		o_vpu0_rqd_rd <= 1'b0;
		o_vpu1_rqa_rd <= 1'b0;
		o_vpu1_rqd_rd <= 1'b0;
	end
	else if(rx_fsm == FSM_RX_RDCU)
	begin
		/* Store incoming request to outgoing FIFO */
		if(i_cu_rqa_vld)
		begin
			m_rqa_fifo[m_rqa_fifo_wp[1:0]] <= i_cu_rqa;
			m_rqa_fifo_wp <= m_rqa_fifo_wp + 1'b1;
		end

		/* Determine next state */
		if(fifo_stall)
		begin
			rx_fsm <= FSM_RX_STLL;
			stall_s <= rx_fsm;
			o_cu_rqa_rd <= 1'b0;
		end
		else if(i_vpu0_rqa_vld)
		begin
			rx_fsm <= FSM_RX_RDV0;
			o_cu_rqa_rd <= 1'b0;
			o_vpu0_rqa_rd <= 1'b1;
			o_vpu0_rqd_rd <= ~v0_data_hold_vld;
		end
		else if(i_vpu1_rqa_vld)
		begin
			rx_fsm <= FSM_RX_RDV1;
			o_cu_rqa_rd <= 1'b0;
			o_vpu1_rqa_rd <= 1'b1;
			o_vpu1_rqd_rd <= ~v1_data_hold_vld;
		end
	end
	else if(rx_fsm == FSM_RX_RDV0)
	begin
		if(i_vpu0_rqa_vld)
		begin
			/* Copy request to outgoing FIFO */
			m_rqa_fifo[m_rqa_fifo_wp[1:0]] <= i_vpu0_rqa;
			m_rqa_fifo_wp <= m_rqa_fifo_wp + 1'b1;

			if(v0_data_hold_vld && ~rqav0_rnw)
			begin
				/* If request is WRITE and hold register is
				 * valid then copy data from the hold register
				 * to outgoing data FIFO. The re-enable reads
				 * from data channel.
				 */
				m_rqd_fifo[m_rqd_fifo_wp[1:0]] <= v0_data_hold_r;
				m_rqd_fifo_wp <= m_rqd_fifo_wp + 1'b1;
				v0_data_hold_vld <= 1'b0;
				o_vpu0_rqd_rd <= 1'b1;
			end
			else if(~v0_data_hold_vld && i_vpu0_rqd_vld && rqav0_rnw)
			begin
				/* If request is READ, incoming data is valid
				 * and hold register is not valid then copy data
				 * to the hold register and disable further
				 * reads from data channel.
				 *
				 * It is required to keep proper order of
				 * request and data channels.
				 */
				v0_data_hold_r <= i_vpu0_rqd;
				v0_data_hold_vld <= 1'b1;
				o_vpu0_rqd_rd <= 1'b0;
			end
			else if(i_vpu0_rqd_vld && ~rqav0_rnw)
			begin
				/* If request is WRITE and incoming data is
				 * valid then copy data to outgoing data FIFO.
				 */
				m_rqd_fifo[m_rqd_fifo_wp[1:0]] <= i_vpu0_rqd;
				m_rqd_fifo_wp <= m_rqd_fifo_wp + 1'b1;
			end
			else if(~i_vpu0_rqd_vld && ~rqav0_rnw)
			begin
				/* This case should never happen */
				$display("Err: ~i_vpu0_rqd_vld && ~rqav0_rnw");
			end
		end


		/* Determine next state */
		if(fifo_stall)
		begin
			rx_fsm <= FSM_RX_STLL;
			stall_s <= rx_fsm;
			o_vpu0_rqa_rd <= 1'b0;
			o_vpu0_rqd_rd <= 1'b0;
		end
		else if(i_vpu1_rqa_vld)
		begin
			rx_fsm <= FSM_RX_RDV1;
			o_vpu0_rqa_rd <= 1'b0;
			o_vpu0_rqd_rd <= 1'b0;
			o_vpu1_rqa_rd <= 1'b1;
			o_vpu1_rqd_rd <= ~v1_data_hold_vld;
		end
		else if(i_cu_rqa_vld)
		begin
			rx_fsm <= FSM_RX_RDCU;
			o_vpu0_rqa_rd <= 1'b0;
			o_vpu0_rqd_rd <= 1'b0;
			o_cu_rqa_rd <= 1'b1;
		end
	end
	else if(rx_fsm == FSM_RX_RDV1)
	begin
		if(i_vpu1_rqa_vld)
		begin
			/* Copy request to outgoing FIFO */
			m_rqa_fifo[m_rqa_fifo_wp[1:0]] <= i_vpu1_rqa;
			m_rqa_fifo_wp <= m_rqa_fifo_wp + 1'b1;

			if(v1_data_hold_vld && ~rqav1_rnw)
			begin
				/* If request is WRITE and hold register is
				 * valid then copy data from the hold register
				 * to outgoing data FIFO. The re-enable reads
				 * from data channel.
				 */
				m_rqd_fifo[m_rqd_fifo_wp[1:0]] <= v1_data_hold_r;
				m_rqd_fifo_wp <= m_rqd_fifo_wp + 1'b1;
				v1_data_hold_vld <= 1'b0;
				o_vpu1_rqd_rd <= 1'b1;
			end
			else if(~v1_data_hold_vld && i_vpu1_rqd_vld && rqav1_rnw)
			begin
				/* If request is READ, incoming data is valid
				 * and hold register is not valid then copy data
				 * to the hold register and disable further
				 * reads from data channel.
				 *
				 * It is required to keep proper order of
				 * request and data channels.
				 */
				v1_data_hold_r <= i_vpu1_rqd;
				v1_data_hold_vld <= 1'b1;
				o_vpu1_rqd_rd <= 1'b0;
			end
			else if(i_vpu1_rqd_vld && ~rqav1_rnw)
			begin
				/* If request is WRITE and incoming data is
				 * valid then copy data to outgoing data FIFO.
				 */
				m_rqd_fifo[m_rqd_fifo_wp[1:0]] <= i_vpu1_rqd;
				m_rqd_fifo_wp <= m_rqd_fifo_wp + 1'b1;
			end
			else if(~i_vpu1_rqd_vld && ~rqav1_rnw)
			begin
				/* This case should never happen */
				$display("Err: ~i_vpu1_rqd_vld && ~rqav1_rnw");
			end
		end


		/* Determine next state */
		if(fifo_stall)
		begin
			rx_fsm <= FSM_RX_STLL;
			stall_s <= rx_fsm;
			o_vpu1_rqa_rd <= 1'b0;
			o_vpu1_rqd_rd <= 1'b0;
		end
		else if(i_cu_rqa_vld)
		begin
			rx_fsm <= FSM_RX_RDCU;
			o_vpu1_rqa_rd <= 1'b0;
			o_vpu1_rqd_rd <= 1'b0;
			o_cu_rqa_rd <= 1'b1;
		end
		else if(i_vpu0_rqa_vld)
		begin
			rx_fsm <= FSM_RX_RDV0;
			o_vpu1_rqa_rd <= 1'b0;
			o_vpu1_rqd_rd <= 1'b0;
			o_vpu0_rqa_rd <= 1'b1;
			o_vpu0_rqd_rd <= ~v0_data_hold_vld;
		end
	end
	else if(rx_fsm == FSM_RX_STLL)
	begin
		if(!fifo_stall)
		begin
			rx_fsm <= FSM_RX_IDLE;

			/* Recover from the stall. Check client readiness in
			 * order documented above.
			 */
			case(stall_s)
			FSM_RX_RDCU: begin
				/* RDCU -> RDV0 -> RDV1 */
				if(i_vpu0_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDV0;
					o_vpu0_rqa_rd <= 1'b1;
					o_vpu0_rqd_rd <= ~v0_data_hold_vld;
				end
				else if(i_vpu1_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDV1;
					o_vpu1_rqa_rd <= 1'b1;
					o_vpu1_rqd_rd <= ~v1_data_hold_vld;
				end
				else if(i_cu_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDCU;
					o_cu_rqa_rd <= 1'b1;
				end
			end
			FSM_RX_RDV0: begin
				/* RDV0 -> RDV1 -> RDCU */
				if(i_vpu1_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDV1;
					o_vpu1_rqa_rd <= 1'b1;
					o_vpu1_rqd_rd <= ~v1_data_hold_vld;
				end
				else if(i_cu_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDCU;
					o_cu_rqa_rd <= 1'b1;
				end
				else if(i_vpu0_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDV0;
					o_vpu0_rqa_rd <= 1'b1;
					o_vpu0_rqd_rd <= ~v0_data_hold_vld;
				end
			end
			FSM_RX_RDV1: begin
				/* RDV1 -> RDCU -> RDV0 */
				if(i_cu_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDCU;
					o_cu_rqa_rd <= 1'b1;
				end
				else if(i_vpu0_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDV0;
					o_vpu0_rqa_rd <= 1'b1;
					o_vpu0_rqd_rd <= ~v0_data_hold_vld;
				end
				else if(i_vpu1_rqa_vld)
				begin
					rx_fsm <= FSM_RX_RDV1;
					o_vpu1_rqa_rd <= 1'b1;
					o_vpu1_rqd_rd <= ~v1_data_hold_vld;
				end
			end
			default: begin
				rx_fsm <= FSM_RX_IDLE;
				/* Should not happen */
				$display("Err: case(stall_s) -> default");
			end
			endcase
		end
	end
	else /* IDLE */
	begin
		if(i_cu_rqa_vld == 1'b1)
		begin
			rx_fsm <= FSM_RX_RDCU;
			o_cu_rqa_rd <= 1'b1;
		end
		else if(i_vpu0_rqa_vld == 1'b1)
		begin
			rx_fsm <= FSM_RX_RDV0;
			o_vpu0_rqa_rd <= 1'b1;
			o_vpu0_rqd_rd <= 1'b1;
		end
		else if(i_vpu1_rqa_vld == 1'b1)
		begin
			rx_fsm <= FSM_RX_RDV1;
			o_vpu1_rqa_rd <= 1'b1;
			o_vpu1_rqd_rd <= 1'b1;
		end
	end
end



/* Address TX FSM state */
reg	txa_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		txa_fsm <= FSM_TX_IDLE;
		m_rqa_fifo_rp <= 3'b000;
		o_m_rqa_wr <= 1'b0;
	end
	else if(txa_fsm == FSM_TX_IDLE)
	begin
		if(!m_rqa_fifo_empty)
		begin
			txa_fsm <= FSM_TX_SEND;
			o_m_rqa <= m_rqa_fifo[m_rqa_fifo_rp[1:0]];
			m_rqa_fifo_rp <= m_rqa_fifo_rp + 1'b1;
			o_m_rqa_wr <= 1'b1;
		end
	end
	else if(txa_fsm == FSM_TX_SEND)
	begin
		if(i_m_rqa_rdy && !m_rqa_fifo_empty)
		begin
			o_m_rqa <= m_rqa_fifo[m_rqa_fifo_rp[1:0]];
			m_rqa_fifo_rp <= m_rqa_fifo_rp + 1'b1;
		end
		else if(i_m_rqa_rdy)
		begin
			txa_fsm <= FSM_TX_IDLE;
			o_m_rqa_wr <= 1'b0;
		end
	end
end



/* Data TX FSM state */
reg	txd_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		txd_fsm <= FSM_TX_IDLE;
		m_rqd_fifo_rp <= 3'b000;
		o_m_rqd_wr <= 1'b0;
	end
	else if(txd_fsm == FSM_TX_IDLE)
	begin
		if(!m_rqd_fifo_empty)
		begin
			txd_fsm <= FSM_TX_SEND;
			o_m_rqd <= m_rqd_fifo[m_rqd_fifo_rp[1:0]];
			m_rqd_fifo_rp <= m_rqd_fifo_rp + 1'b1;
			o_m_rqd_wr <= 1'b1;
		end
	end
	else if(txd_fsm == FSM_TX_SEND)
	begin
		if(i_m_rqd_rdy && !m_rqd_fifo_empty)
		begin
			o_m_rqd <= m_rqd_fifo[m_rqd_fifo_rp[1:0]];
			m_rqd_fifo_rp <= m_rqd_fifo_rp + 1'b1;
		end
		else if(i_m_rqd_rdy)
		begin
			txd_fsm <= FSM_TX_IDLE;
			o_m_rqd_wr <= 1'b0;
		end
	end
end



/* VPU0 request decoder */
vxe_txnreqa_decoder reqav0_decode(
	.i_req_vec_txn(i_vpu0_rqa),
	.o_txnid(rqav0_txnid),
	.o_rnw(rqav0_rnw),
	.o_addr(rqav0_addr)
);


/* VPU1 request decoder */
vxe_txnreqa_decoder reqav1_decode(
	.i_req_vec_txn(i_vpu1_rqa),
	.o_txnid(rqav1_txnid),
	.o_rnw(rqav1_rnw),
	.o_addr(rqav1_addr)
);


endmodule /* vxe_mem_hub_mas_us */
