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
 * AXI4 memory port
 */

#include <cstdint>
#include <vector>
#include <systemc.h>
#include "axi4_internal.hxx"
#pragma once


// Memory port
SC_MODULE(axi4_mem_port) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// AXI4 interface signals
	sc_in<uint32_t>		AWID;
	sc_in<uint64_t>		AWADDR;
	sc_in<uint32_t>		AWLEN;
	sc_in<uint32_t>		AWSIZE;
	sc_in<uint32_t>		AWBURST;
	sc_in<bool>		AWLOCK;
	sc_in<uint32_t>		AWCACHE;
	sc_in<uint32_t>		AWPROT;
	sc_in<bool>		AWVALID;
	sc_out<bool>		AWREADY;
	sc_in<uint64_t>		WDATA;
	sc_in<uint32_t>		WSTRB;
	sc_in<bool>		WLAST;
	sc_in<bool>		WVALID;
	sc_out<bool>		WREADY;
	sc_out<uint32_t>	BID;
	sc_out<uint32_t>	BRESP;
	sc_out<bool>		BVALID;
	sc_in<bool>		BREADY;
	sc_in<uint32_t>		ARID;
	sc_in<uint64_t>		ARADDR;
	sc_in<uint32_t>		ARLEN;
	sc_in<uint32_t>		ARSIZE;
	sc_in<uint32_t>		ARBURST;
	sc_in<bool>		ARLOCK;
	sc_in<uint32_t>		ARCACHE;
	sc_in<uint32_t>		ARPROT;
	sc_in<bool>		ARVALID;
	sc_out<bool>		ARREADY;
	sc_out<uint32_t>	RID;
	sc_out<uint64_t>	RDATA;
	sc_out<uint32_t>	RRESP;
	sc_out<bool>		RLAST;
	sc_out<bool>		RVALID;
	sc_in<bool>		RREADY;

	SC_HAS_PROCESS(axi4_mem_port);

	axi4_mem_port(::sc_core::sc_module_name name, std::vector<uint8_t> &m)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, AWID("AWID"), AWADDR("AWADDR"), AWLEN("AWLEN"), AWSIZE("AWSIZE")
		, AWBURST("AWBURST"), AWLOCK("AWLOCK"), AWCACHE("AWCACHE"), AWPROT("AWPROT")
		, AWVALID("AWVALID"), AWREADY("AWREADY"), WDATA("WDATA"), WSTRB("WSTRB")
		, WLAST("WLAST"), WVALID("WVALID"), WREADY("WREADY"), BID("BID")
		, BRESP("BRESP"), BVALID("BVALID"), BREADY("BREADY")
		, ARID("ARID"), ARADDR("ARADDR"), ARLEN("ARLEN"), ARSIZE("ARSIZE")
		, ARBURST("ARBURST"), ARLOCK("ARLOCK"), ARCACHE("ARCACHE"), ARPROT("ARPROT")
		, ARVALID("ARVALID"), ARREADY("ARREADY"), RID("RID")
		, RDATA("RDATA"), RRESP("RRESP"), RLAST("RLAST"), RVALID("RVALID")
		, RREADY("RREADY")
		, mem(m)
	{
		SC_THREAD(wr_addr_thread);
			sensitive << clk.pos();

		SC_THREAD(wr_data_thread);
			sensitive << clk.pos();

		SC_THREAD(wr_resp_thread);
			sensitive << clk.pos();

		SC_THREAD(rd_addr_thread);
			sensitive << clk.pos();

		SC_THREAD(rd_resp_thread);
			sensitive << clk.pos();

		SC_THREAD(process_wr_thread)
			sensitive << clk.pos();

		SC_THREAD(process_rd_thread)
			sensitive << clk.pos();

		set_delays(0, 0, 0);
	}

	void set_delays(unsigned ar, unsigned aw, unsigned w)
	{
		m_ardelay = ar;
		m_awdelay = aw;
		m_wdelay = w;
	}

private:
	// Write Address channel (AW)
	[[noreturn]] void wr_addr_thread()
	{
		AWREADY.write(true);

		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			bool ready = fifo_awaddr.num_free() != 0;

			// Simulate channel delay
			if(m_awdelay) {
				unsigned n = m_awdelay;
				AWREADY.write(false);
				while(n--) wait();
			}

			AWREADY.write(ready);
			wait();

			if(!AWVALID.read() || !ready) {
				continue;
			}

			axi4::awaddr wr;

			// Convert to AWADDR structure
			wr.awid		= AWID.read();
			wr.awaddr	= AWADDR.read();
			wr.awlen	= AWLEN.read();
			wr.awsize	= AWSIZE.read();
			wr.awburst	= AWBURST.read();
			wr.awlock	= AWLOCK.read();
			wr.awcache	= AWCACHE.read();
			wr.awprot	= AWPROT.read();

			// Send for processing
			fifo_awaddr.write(wr);
		}
	}

	// Write Data channel (W)
	[[noreturn]] void wr_data_thread()
	{
		WREADY.write(true);

		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			bool ready = fifo_wdata.num_free() != 0;

			// Simulate channel delay
			if(m_wdelay) {
				unsigned n = m_wdelay;
				WREADY.write(false);
				while(n--) wait();
			}

			WREADY.write(ready);
			wait();

			if(!WVALID.read() || !ready) {
				continue;
			}

			axi4::wdata wd;

			// Convert to WDATA structure
			wd.wdata = WDATA.read();
			wd.wstrb = WSTRB.read();
			wd.wlast = WLAST.read();

			// Send for processing
			fifo_wdata.write(wd);
		}
	}

	// Write Response channel (B)
	[[noreturn]] void wr_resp_thread()
	{
		BVALID.write(false);

		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			bool valid = fifo_bresp.num_available() != 0;

			BVALID.write(valid);

			if(valid) {
				// Receive response
				axi4::bresp br = fifo_bresp.read();

				// Convert to AXI signals
				BID.write(br.bid);
				BRESP.write(br.bresp);
			}

			do {
				wait();
			} while(!BREADY.read());
		}
	}

	// Read Address channel (AR)
	[[noreturn]] void rd_addr_thread()
	{
		ARREADY.write(true);

		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			bool ready = fifo_araddr.num_free() != 0;

			// Simulate channel delay
			if(m_ardelay) {
				unsigned n = m_ardelay;
				ARREADY.write(false);
				while(n--) wait();
			}

			ARREADY.write(ready);
			wait();

			if(!ARVALID.read() || !ready) {
				continue;
			}

			axi4::araddr rd;

			// Convert to ARADDR structure
			rd.arid		= ARID.read();
			rd.araddr	= ARADDR.read();
			rd.arlen	= ARLEN.read();
			rd.arsize	= ARSIZE.read();
			rd.arburst	= ARBURST.read();
			rd.arlock	= ARLOCK.read();
			rd.arcache	= ARCACHE.read();
			rd.arprot	= ARPROT.read();

			// Send for processing
			fifo_araddr.write(rd);
		}
	}

	// Read Data channel (R)
	[[noreturn]] void rd_resp_thread()
	{
		RVALID.write(false);

		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			bool valid = fifo_rresp.num_available() != 0;

			RVALID.write(valid);

			if(valid) {
				// Receive response
				axi4::rresp rr = fifo_rresp.read();

				// Convert to AXI signals
				RID.write(rr.rid);
				RDATA.write(rr.rdata);
				RRESP.write(rr.rresp);
			}

			do {
				wait();
			} while(!RREADY.read());
		}
	}

	/**
	 * Merge data based on strb value
	 * @param oldd Old data word
	 * @param newd New data word
	 * @param strb Strb value
	 * @return Merged data
	 */
	uint64_t merge_data(uint64_t oldd, uint64_t newd, uint32_t strb)
	{
		uint64_t mask = 0;
		int i;

		// Create mask based on strb bits
		for(i=0; i < 8; ++i) {
			if(strb & (1 << i))
				mask |= 0xFFULL << i*8;
		}

		// Mask data
		oldd &= ~mask;
		newd &= mask;

		// Merge and return
		return oldd | newd;
	}

	// Writes processing thread
	[[noreturn]] void process_wr_thread()
	{
		while(true) {
			axi4::awaddr aw = fifo_awaddr.read();	// Receive address
			axi4::wdata wd = fifo_wdata.read();	// Receive data

			if(aw.awaddr & 3)
				std::cerr << name() << ": Write address is not properly aligned!" << std::endl;

			uint64_t addr = aw.awaddr & ~3;
			axi4::bresp br;

			// Update memory / prepare response
			if(addr < mem.size() && wd.wstrb == 0xFF) {
				br.bid = aw.awid;
				br.bresp = axi4::resp::OKAY;
				*reinterpret_cast<uint64_t*>(&mem[addr]) = wd.wdata;
			} else if(addr < mem.size() && wd.wstrb != 0xFF) {
				br.bid = aw.awid;
				br.bresp = axi4::resp::OKAY;
				uint64_t mdata = *reinterpret_cast<uint64_t*>(&mem[addr]);
				*reinterpret_cast<uint64_t*>(&mem[addr]) = merge_data(mdata, wd.wdata, wd.wstrb);
			} else {
				std::cerr << name() << ": Write address is out of range!" << std::endl;
				br.bid = aw.awid;
				br.bresp = axi4::resp::SLVERR;
			}

			// Send response
			fifo_bresp.write(br);
		}
	}

	// Reads processing thread
	[[noreturn]] void process_rd_thread()
	{
		while(true) {
			axi4::araddr ar = fifo_araddr.read();

			if(ar.araddr & 3)
				std::cerr << name() << ": Read address is not properly aligned!" << std::endl;

			uint64_t addr = ar.araddr & ~3;
			axi4::rresp rr;

			// Prepare response
			if(addr < mem.size()) {
				rr.rid = ar.arid;
				rr.rresp = axi4::resp::OKAY;
				rr.rdata = *reinterpret_cast<uint64_t*>(&mem[addr]);
			} else {
				std::cerr << name() << ": Read address is out of range!" << std::endl;
				rr.rid = ar.arid;
				rr.rresp = axi4::resp::SLVERR;
				rr.rdata = 0;
			}

			// Send response
			fifo_rresp.write(rr);
		}
	}

private:
	std::vector<uint8_t>	&mem;		// Memory reference
	sc_fifo<axi4::awaddr>	fifo_awaddr;	// Write Address FIFO
	sc_fifo<axi4::wdata>	fifo_wdata;	// Write Data FIFO
	sc_fifo<axi4::bresp>	fifo_bresp;	// Write Response FIFO
	sc_fifo<axi4::araddr>	fifo_araddr;	// Read Address FIFO
	sc_fifo<axi4::rresp>	fifo_rresp;	// Read Data FIFO
	unsigned		m_ardelay;	// AXI AR channel delay
	unsigned		m_awdelay;	// AXI AW channel delay
	unsigned		m_wdelay;	// AXI W channel delay
};
