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
 * VxEngine top wrapper
 */

#include <cstdint>
#include <systemc.h>
#include "axi4_proto.hxx"
#include "obj_dir/Vvxe_top.h"
#pragma once


// VxEngine top module
SC_MODULE(vxe_top_wrapper) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// Interrupt line
	sc_out<bool> o_intr;

	// Slave I/O port
	sc_fifo_in<axi4::areq32> s0_aw_fifo_in;
	sc_fifo_in<axi4::wreq32> s0_w_fifo_in;
	sc_fifo_out<axi4::bresp32> s0_b_fifo_out;
	sc_fifo_in<axi4::areq32> s0_ar_fifo_in;
	sc_fifo_out<axi4::rresp32> s0_r_fifo_out;

	// Master mem port 0
	sc_fifo_out<axi4::areq64> m0_aw_fifo_out;
	sc_fifo_out<axi4::wreq64> m0_w_fifo_out;
	sc_fifo_in<axi4::bresp64> m0_b_fifo_in;
	sc_fifo_out<axi4::areq64> m0_ar_fifo_out;
	sc_fifo_in<axi4::rresp64> m0_r_fifo_in;

	// Master mem port 1
	sc_fifo_out<axi4::areq64> m1_aw_fifo_out;
	sc_fifo_out<axi4::wreq64> m1_w_fifo_out;
	sc_fifo_in<axi4::bresp64> m1_b_fifo_in;
	sc_fifo_out<axi4::areq64> m1_ar_fifo_out;
	sc_fifo_in<axi4::rresp64> m1_r_fifo_in;


	// VxEngine Verilated top
	Vvxe_top vxe_top;

	SC_CTOR(vxe_top_wrapper)
		: clk("clk"), nrst("nrst")
		, o_intr("o_intr")
		, s0_aw_fifo_in("s0_aw_fifo_in"), s0_w_fifo_in("s0_w_fifo_in"), s0_b_fifo_out("s0_b_fifo_out")
		, s0_ar_fifo_in("s0_ar_fifo_in"), s0_r_fifo_out("s0_r_fifo_out")
		, m0_aw_fifo_out("m0_aw_fifo_out"), m0_w_fifo_out("m0_w_fifo_out"), m0_b_fifo_in("m0_b_fifo_in")
		, m0_ar_fifo_out("m0_ar_fifo_out"), m0_r_fifo_in("m0_r_fifo_in")
		, m1_aw_fifo_out("m1_aw_fifo_out"), m1_w_fifo_out("m1_w_fifo_out"), m1_b_fifo_in("m1_b_fifo_in")
		, m1_ar_fifo_out("m1_ar_fifo_out"), m1_r_fifo_in("m1_r_fifo_in")
		, vxe_top("vxe_top")
	{
		SC_THREAD(s0_aw_thread);
			sensitive << clk.pos();

		SC_THREAD(s0_w_thread);
			sensitive << clk.pos();

		SC_THREAD(s0_b_thread);
			sensitive << clk.pos();

		SC_THREAD(s0_ar_thread);
			sensitive << clk.pos();

		SC_THREAD(s0_r_thread);
			sensitive << clk.pos();

		SC_THREAD(m0_aw_thread);
			sensitive << clk.pos();

		SC_THREAD(m0_w_thread);
			sensitive << clk.pos();

		SC_THREAD(m0_b_thread);
			sensitive << clk.pos();

		SC_THREAD(m0_ar_thread);
			sensitive << clk.pos();

		SC_THREAD(m0_r_thread);
			sensitive << clk.pos();

		SC_THREAD(m1_aw_thread);
			sensitive << clk.pos();

		SC_THREAD(m1_w_thread);
			sensitive << clk.pos();

		SC_THREAD(m1_b_thread);
			sensitive << clk.pos();

		SC_THREAD(m1_ar_thread);
			sensitive << clk.pos();

		SC_THREAD(m1_r_thread);
			sensitive << clk.pos();

		// Connect VxE signals
		vxe_top.clk(clk);
		vxe_top.nrst(nrst);
		vxe_top.o_intr(o_intr);
		// AXI4 Slave 0
		vxe_top.S0_AXI4_AWID(S0_AXI4_AWID);
		vxe_top.S0_AXI4_AWADDR(S0_AXI4_AWADDR);
		vxe_top.S0_AXI4_AWLEN(S0_AXI4_AWLEN);
		vxe_top.S0_AXI4_AWSIZE(S0_AXI4_AWSIZE);
		vxe_top.S0_AXI4_AWBURST(S0_AXI4_AWBURST);
		vxe_top.S0_AXI4_AWLOCK(S0_AXI4_AWLOCK);
		vxe_top.S0_AXI4_AWCACHE(S0_AXI4_AWCACHE);
		vxe_top.S0_AXI4_AWPROT(S0_AXI4_AWPROT);
		vxe_top.S0_AXI4_AWVALID(S0_AXI4_AWVALID);
		vxe_top.S0_AXI4_AWREADY(S0_AXI4_AWREADY);
		vxe_top.S0_AXI4_WDATA(S0_AXI4_WDATA);
		vxe_top.S0_AXI4_WSTRB(S0_AXI4_WSTRB);
		vxe_top.S0_AXI4_WLAST(S0_AXI4_WLAST);
		vxe_top.S0_AXI4_WVALID(S0_AXI4_WVALID);
		vxe_top.S0_AXI4_WREADY(S0_AXI4_WREADY);
		vxe_top.S0_AXI4_BID(S0_AXI4_BID);
		vxe_top.S0_AXI4_BRESP(S0_AXI4_BRESP);
		vxe_top.S0_AXI4_BVALID(S0_AXI4_BVALID);
		vxe_top.S0_AXI4_BREADY(S0_AXI4_BREADY);
		vxe_top.S0_AXI4_ARID(S0_AXI4_ARID);
		vxe_top.S0_AXI4_ARADDR(S0_AXI4_ARADDR);
		vxe_top.S0_AXI4_ARLEN(S0_AXI4_ARLEN);
		vxe_top.S0_AXI4_ARSIZE(S0_AXI4_ARSIZE);
		vxe_top.S0_AXI4_ARBURST(S0_AXI4_ARBURST);
		vxe_top.S0_AXI4_ARLOCK(S0_AXI4_ARLOCK);
		vxe_top.S0_AXI4_ARCACHE(S0_AXI4_ARCACHE);
		vxe_top.S0_AXI4_ARPROT(S0_AXI4_ARPROT);
		vxe_top.S0_AXI4_ARVALID(S0_AXI4_ARVALID);
		vxe_top.S0_AXI4_ARREADY(S0_AXI4_ARREADY);
		vxe_top.S0_AXI4_RID(S0_AXI4_RID);
		vxe_top.S0_AXI4_RDATA(S0_AXI4_RDATA);
		vxe_top.S0_AXI4_RRESP(S0_AXI4_RRESP);
		vxe_top.S0_AXI4_RLAST(S0_AXI4_RLAST);
		vxe_top.S0_AXI4_RVALID(S0_AXI4_RVALID);
		vxe_top.S0_AXI4_RREADY(S0_AXI4_RREADY);
		// AXI4 Master 0
		vxe_top.M0_AXI4_AWID(M0_AXI4_AWID);
		vxe_top.M0_AXI4_AWADDR(M0_AXI4_AWADDR);
		vxe_top.M0_AXI4_AWLEN(M0_AXI4_AWLEN);
		vxe_top.M0_AXI4_AWSIZE(M0_AXI4_AWSIZE);
		vxe_top.M0_AXI4_AWBURST(M0_AXI4_AWBURST);
		vxe_top.M0_AXI4_AWLOCK(M0_AXI4_AWLOCK);
		vxe_top.M0_AXI4_AWCACHE(M0_AXI4_AWCACHE);
		vxe_top.M0_AXI4_AWPROT(M0_AXI4_AWPROT);
		vxe_top.M0_AXI4_AWVALID(M0_AXI4_AWVALID);
		vxe_top.M0_AXI4_AWREADY(M0_AXI4_AWREADY);
		vxe_top.M0_AXI4_WDATA(M0_AXI4_WDATA);
		vxe_top.M0_AXI4_WSTRB(M0_AXI4_WSTRB);
		vxe_top.M0_AXI4_WLAST(M0_AXI4_WLAST);
		vxe_top.M0_AXI4_WVALID(M0_AXI4_WVALID);
		vxe_top.M0_AXI4_WREADY(M0_AXI4_WREADY);
		vxe_top.M0_AXI4_BID(M0_AXI4_BID);
		vxe_top.M0_AXI4_BRESP(M0_AXI4_BRESP);
		vxe_top.M0_AXI4_BVALID(M0_AXI4_BVALID);
		vxe_top.M0_AXI4_BREADY(M0_AXI4_BREADY);
		vxe_top.M0_AXI4_ARID(M0_AXI4_ARID);
		vxe_top.M0_AXI4_ARADDR(M0_AXI4_ARADDR);
		vxe_top.M0_AXI4_ARLEN(M0_AXI4_ARLEN);
		vxe_top.M0_AXI4_ARSIZE(M0_AXI4_ARSIZE);
		vxe_top.M0_AXI4_ARBURST(M0_AXI4_ARBURST);
		vxe_top.M0_AXI4_ARLOCK(M0_AXI4_ARLOCK);
		vxe_top.M0_AXI4_ARCACHE(M0_AXI4_ARCACHE);
		vxe_top.M0_AXI4_ARPROT(M0_AXI4_ARPROT);
		vxe_top.M0_AXI4_ARVALID(M0_AXI4_ARVALID);
		vxe_top.M0_AXI4_ARREADY(M0_AXI4_ARREADY);
		vxe_top.M0_AXI4_RID(M0_AXI4_RID);
		vxe_top.M0_AXI4_RDATA(M0_AXI4_RDATA);
		vxe_top.M0_AXI4_RRESP(M0_AXI4_RRESP);
		vxe_top.M0_AXI4_RLAST(M0_AXI4_RLAST);
		vxe_top.M0_AXI4_RVALID(M0_AXI4_RVALID);
		vxe_top.M0_AXI4_RREADY(M0_AXI4_RREADY);
		// AXI4 Master 1
		vxe_top.M1_AXI4_AWID(M1_AXI4_AWID);
		vxe_top.M1_AXI4_AWADDR(M1_AXI4_AWADDR);
		vxe_top.M1_AXI4_AWLEN(M1_AXI4_AWLEN);
		vxe_top.M1_AXI4_AWSIZE(M1_AXI4_AWSIZE);
		vxe_top.M1_AXI4_AWBURST(M1_AXI4_AWBURST);
		vxe_top.M1_AXI4_AWLOCK(M1_AXI4_AWLOCK);
		vxe_top.M1_AXI4_AWCACHE(M1_AXI4_AWCACHE);
		vxe_top.M1_AXI4_AWPROT(M1_AXI4_AWPROT);
		vxe_top.M1_AXI4_AWVALID(M1_AXI4_AWVALID);
		vxe_top.M1_AXI4_AWREADY(M1_AXI4_AWREADY);
		vxe_top.M1_AXI4_WDATA(M1_AXI4_WDATA);
		vxe_top.M1_AXI4_WSTRB(M1_AXI4_WSTRB);
		vxe_top.M1_AXI4_WLAST(M1_AXI4_WLAST);
		vxe_top.M1_AXI4_WVALID(M1_AXI4_WVALID);
		vxe_top.M1_AXI4_WREADY(M1_AXI4_WREADY);
		vxe_top.M1_AXI4_BID(M1_AXI4_BID);
		vxe_top.M1_AXI4_BRESP(M1_AXI4_BRESP);
		vxe_top.M1_AXI4_BVALID(M1_AXI4_BVALID);
		vxe_top.M1_AXI4_BREADY(M1_AXI4_BREADY);
		vxe_top.M1_AXI4_ARID(M1_AXI4_ARID);
		vxe_top.M1_AXI4_ARADDR(M1_AXI4_ARADDR);
		vxe_top.M1_AXI4_ARLEN(M1_AXI4_ARLEN);
		vxe_top.M1_AXI4_ARSIZE(M1_AXI4_ARSIZE);
		vxe_top.M1_AXI4_ARBURST(M1_AXI4_ARBURST);
		vxe_top.M1_AXI4_ARLOCK(M1_AXI4_ARLOCK);
		vxe_top.M1_AXI4_ARCACHE(M1_AXI4_ARCACHE);
		vxe_top.M1_AXI4_ARPROT(M1_AXI4_ARPROT);
		vxe_top.M1_AXI4_ARVALID(M1_AXI4_ARVALID);
		vxe_top.M1_AXI4_ARREADY(M1_AXI4_ARREADY);
		vxe_top.M1_AXI4_RID(M1_AXI4_RID);
		vxe_top.M1_AXI4_RDATA(M1_AXI4_RDATA);
		vxe_top.M1_AXI4_RRESP(M1_AXI4_RRESP);
		vxe_top.M1_AXI4_RLAST(M1_AXI4_RLAST);
		vxe_top.M1_AXI4_RVALID(M1_AXI4_RVALID);
		vxe_top.M1_AXI4_RREADY(M1_AXI4_RREADY);
	}

private:
	[[noreturn]] void s0_aw_thread()
	{
		// Reset values
		S0_AXI4_AWLEN.write(0);
		S0_AXI4_AWSIZE.write(0);
		S0_AXI4_AWBURST.write(0);
		S0_AXI4_AWLOCK.write(false);
		S0_AXI4_AWCACHE.write(0);
		S0_AXI4_AWPROT.write(0);
		S0_AXI4_AWVALID.write(false);

		while(true) {
			wait();

			axi4::areq32 wrq = s0_aw_fifo_in.read();

			S0_AXI4_AWID.write(wrq.id);
			S0_AXI4_AWADDR.write(wrq.addr);
			S0_AXI4_AWVALID.write(true);

			wait();
			while(S0_AXI4_AWREADY.read() != true)
				wait();

			S0_AXI4_AWVALID.write(false);
		}
	}

	[[noreturn]] void s0_w_thread()
	{
		// Reset values
		S0_AXI4_WSTRB.write(0xf);
		S0_AXI4_WLAST.write(true);
		S0_AXI4_WVALID.write(false);

		while(true) {
			wait();

			axi4::wreq32 wrq = s0_w_fifo_in.read();

			S0_AXI4_WDATA.write(wrq.data);
			S0_AXI4_WVALID.write(true);

			wait();
			while(S0_AXI4_WREADY.read() != true)
				wait();

			S0_AXI4_WVALID.write(false);
		}
	}

	[[noreturn]] void s0_b_thread()
	{
		// Reset values
		S0_AXI4_BREADY.write(true);

		while(true) {
			wait();

			if(S0_AXI4_BVALID.read() == true) {
				axi4::bresp32 brs;

				brs.id = S0_AXI4_BID.read();
				brs.resp = S0_AXI4_BRESP.read();

				s0_b_fifo_out.write(brs);
			}
		}
	}

	[[noreturn]] void s0_ar_thread()
	{
		// Reset values
		S0_AXI4_ARLEN.write(0);
		S0_AXI4_ARSIZE.write(0);
		S0_AXI4_ARBURST.write(0);
		S0_AXI4_ARLOCK.write(false);
		S0_AXI4_ARCACHE.write(0);
		S0_AXI4_ARPROT.write(0);
		S0_AXI4_ARVALID.write(false);

		while(true) {
			wait();

			axi4::areq32 rrq = s0_ar_fifo_in.read();

			S0_AXI4_ARID.write(rrq.id);
			S0_AXI4_ARADDR.write(rrq.addr);
			S0_AXI4_ARVALID.write(true);

			wait();
			while(S0_AXI4_ARREADY.read() != true)
				wait();

			S0_AXI4_ARVALID.write(false);
		}
	}

	[[noreturn]] void s0_r_thread()
	{
		// Reset values
		S0_AXI4_RREADY.write(true);

		while(true) {
			wait();

			if(S0_AXI4_RVALID.read() == true) {
				axi4::rresp32 rrs;

				rrs.id = S0_AXI4_RID.read();
				rrs.resp = S0_AXI4_RRESP.read();
				rrs.data = S0_AXI4_RDATA.read();

				s0_r_fifo_out.write(rrs);
			}
		}
	}

	[[noreturn]] void m0_aw_thread()
	{
		// Reset values
		M0_AXI4_AWREADY.write(true);

		while(true) {
			wait();

			if(M0_AXI4_AWVALID.read() == true) {
				axi4::areq64 wrq;

				wrq.id = M0_AXI4_AWID.read();
				wrq.addr = M0_AXI4_AWADDR.read();

				while(!m0_aw_fifo_out.nb_write(wrq)) {
					M0_AXI4_AWREADY.write(false);
					wait();
					M0_AXI4_AWREADY.write(true);
				}
			}
		}
	}

	[[noreturn]] void m0_w_thread()
	{
		// Reset values
		M0_AXI4_WREADY.write(true);

		while(true) {
			wait();

			if(M0_AXI4_WVALID.read() == true) {
				axi4::wreq64 wrq;

				wrq.strb = M0_AXI4_WSTRB.read();
				wrq.data = M0_AXI4_WDATA.read();

				while(!m0_w_fifo_out.nb_write(wrq)) {
					M0_AXI4_WREADY.write(false);
					wait();
					M0_AXI4_WREADY.write(true);
				}
			}
		}
	}

	[[noreturn]] void m0_b_thread()
	{
		// Reset values
		M0_AXI4_BVALID.write(false);

		while(true) {
			axi4::bresp64 brs;

			while(!m0_b_fifo_in.nb_read(brs)) {
				M0_AXI4_BVALID.write(false);
				wait();
			}

			M0_AXI4_BID.write(brs.id);
			M0_AXI4_BRESP.write(brs.resp);
			M0_AXI4_BVALID.write(true);

			wait();
			while(M0_AXI4_BREADY.read() != true)
				wait();
		}
	}

	[[noreturn]] void m0_ar_thread()
	{
		// Reset values
		M0_AXI4_ARREADY.write(true);

		while(true) {
			wait();

			if(M0_AXI4_ARVALID.read() == true) {
				axi4::areq64 rrq;

				rrq.id = M0_AXI4_ARID.read();
				rrq.addr = M0_AXI4_ARADDR.read();

				while(!m0_ar_fifo_out.nb_write(rrq)) {
					M0_AXI4_ARREADY.write(false);
					wait();
					M0_AXI4_ARREADY.write(true);
				}
			}
		}
	}

	[[noreturn]] void m0_r_thread()
	{
		// Reset values
		M0_AXI4_RLAST.write(true); /* Always last response */
		M0_AXI4_RVALID.write(false);

		while(true) {
			axi4::rresp64 rrs;

			while(!m0_r_fifo_in.nb_read(rrs)) {
				M0_AXI4_RVALID.write(false);
				wait();
			}

			M0_AXI4_RID.write(rrs.id);
			M0_AXI4_RRESP.write(rrs.resp);
			M0_AXI4_RDATA.write(rrs.data);
			M0_AXI4_RVALID.write(true);

			wait();
			while(M0_AXI4_RREADY.read() != true)
				wait();
		}
	}

	[[noreturn]] void m1_aw_thread()
	{
		// Reset values
		M1_AXI4_AWREADY.write(true);

		while(true) {
			wait();

			if(M1_AXI4_AWVALID.read() == true) {
				axi4::areq64 wrq;

				wrq.id = M1_AXI4_AWID.read();
				wrq.addr = M1_AXI4_AWADDR.read();

				while(!m1_aw_fifo_out.nb_write(wrq)) {
					M1_AXI4_AWREADY.write(false);
					wait();
					M1_AXI4_AWREADY.write(true);
				}
			}
		}
	}

	[[noreturn]] void m1_w_thread()
	{
		// Reset values
		M1_AXI4_WREADY.write(true);

		while(true) {
			wait();

			if(M1_AXI4_WVALID.read() == true) {
				axi4::wreq64 wrq;

				wrq.strb = M1_AXI4_WSTRB.read();
				wrq.data = M1_AXI4_WDATA.read();

				while(!m1_w_fifo_out.nb_write(wrq)) {
					M1_AXI4_WREADY.write(false);
					wait();
					M1_AXI4_WREADY.write(true);
				}
			}
		}
	}

	[[noreturn]] void m1_b_thread()
	{
		// Reset values
		M1_AXI4_BVALID.write(false);

		while(true) {
			axi4::bresp64 brs;

			while(!m1_b_fifo_in.nb_read(brs)) {
				M1_AXI4_BVALID.write(false);
				wait();
			}

			M1_AXI4_BID.write(brs.id);
			M1_AXI4_BRESP.write(brs.resp);
			M1_AXI4_BVALID.write(true);

			wait();
			while(M1_AXI4_BREADY.read() != true)
				wait();
		}
	}

	[[noreturn]] void m1_ar_thread()
	{
		// Reset values
		M1_AXI4_ARREADY.write(true);

		while(true) {
			wait();

			if(M1_AXI4_ARVALID.read() == true) {
				axi4::areq64 rrq;

				rrq.id = M1_AXI4_ARID.read();
				rrq.addr = M1_AXI4_ARADDR.read();

				while(!m1_ar_fifo_out.nb_write(rrq)) {
					M1_AXI4_ARREADY.write(false);
					wait();
					M1_AXI4_ARREADY.write(true);
				}
			}
		}
	}

	[[noreturn]] void m1_r_thread()
	{
		// Reset values
		M1_AXI4_RLAST.write(true); /* Always last response */
		M1_AXI4_RVALID.write(false);

		while(true) {
			axi4::rresp64 rrs;

			while(!m1_r_fifo_in.nb_read(rrs)) {
				M1_AXI4_RVALID.write(false);
				wait();
			}

			M1_AXI4_RID.write(rrs.id);
			M1_AXI4_RRESP.write(rrs.resp);
			M1_AXI4_RDATA.write(rrs.data);
			M1_AXI4_RVALID.write(true);

			wait();
			while(M1_AXI4_RREADY.read() != true)
				wait();
		}
	}

private:
	// VxE signals
	// AXI4 Slave 0
	sc_signal<uint32_t> S0_AXI4_AWID;
	sc_signal<uint32_t> S0_AXI4_AWADDR;
	sc_signal<uint32_t> S0_AXI4_AWLEN;
	sc_signal<uint32_t> S0_AXI4_AWSIZE;
	sc_signal<uint32_t> S0_AXI4_AWBURST;
	sc_signal<bool> S0_AXI4_AWLOCK;
	sc_signal<uint32_t> S0_AXI4_AWCACHE;
	sc_signal<uint32_t> S0_AXI4_AWPROT;
	sc_signal<bool> S0_AXI4_AWVALID;
	sc_signal<bool> S0_AXI4_AWREADY;
	sc_signal<uint32_t> S0_AXI4_WDATA;
	sc_signal<uint32_t> S0_AXI4_WSTRB;
	sc_signal<bool> S0_AXI4_WLAST;
	sc_signal<bool> S0_AXI4_WVALID;
	sc_signal<bool> S0_AXI4_WREADY;
	sc_signal<uint32_t> S0_AXI4_BID;
	sc_signal<uint32_t> S0_AXI4_BRESP;
	sc_signal<bool> S0_AXI4_BVALID;
	sc_signal<bool> S0_AXI4_BREADY;
	sc_signal<uint32_t> S0_AXI4_ARID;
	sc_signal<uint32_t> S0_AXI4_ARADDR;
	sc_signal<uint32_t> S0_AXI4_ARLEN;
	sc_signal<uint32_t> S0_AXI4_ARSIZE;
	sc_signal<uint32_t> S0_AXI4_ARBURST;
	sc_signal<bool> S0_AXI4_ARLOCK;
	sc_signal<uint32_t> S0_AXI4_ARCACHE;
	sc_signal<uint32_t> S0_AXI4_ARPROT;
	sc_signal<bool> S0_AXI4_ARVALID;
	sc_signal<bool> S0_AXI4_ARREADY;
	sc_signal<uint32_t> S0_AXI4_RID;
	sc_signal<uint32_t> S0_AXI4_RDATA;
	sc_signal<uint32_t> S0_AXI4_RRESP;
	sc_signal<bool> S0_AXI4_RLAST;
	sc_signal<bool> S0_AXI4_RVALID;
	sc_signal<bool> S0_AXI4_RREADY;
	// AXI4 Master 0
	sc_signal<uint32_t> M0_AXI4_AWID;
	sc_signal<uint64_t> M0_AXI4_AWADDR;
	sc_signal<uint32_t> M0_AXI4_AWLEN;
	sc_signal<uint32_t> M0_AXI4_AWSIZE;
	sc_signal<uint32_t> M0_AXI4_AWBURST;
	sc_signal<bool> M0_AXI4_AWLOCK;
	sc_signal<uint32_t> M0_AXI4_AWCACHE;
	sc_signal<uint32_t> M0_AXI4_AWPROT;
	sc_signal<bool> M0_AXI4_AWVALID;
	sc_signal<bool> M0_AXI4_AWREADY;
	sc_signal<uint64_t> M0_AXI4_WDATA;
	sc_signal<uint32_t> M0_AXI4_WSTRB;
	sc_signal<bool> M0_AXI4_WLAST;
	sc_signal<bool> M0_AXI4_WVALID;
	sc_signal<bool> M0_AXI4_WREADY;
	sc_signal<uint32_t> M0_AXI4_BID;
	sc_signal<uint32_t> M0_AXI4_BRESP;
	sc_signal<bool> M0_AXI4_BVALID;
	sc_signal<bool> M0_AXI4_BREADY;
	sc_signal<uint32_t> M0_AXI4_ARID;
	sc_signal<uint64_t> M0_AXI4_ARADDR;
	sc_signal<uint32_t> M0_AXI4_ARLEN;
	sc_signal<uint32_t> M0_AXI4_ARSIZE;
	sc_signal<uint32_t> M0_AXI4_ARBURST;
	sc_signal<bool> M0_AXI4_ARLOCK;
	sc_signal<uint32_t> M0_AXI4_ARCACHE;
	sc_signal<uint32_t> M0_AXI4_ARPROT;
	sc_signal<bool> M0_AXI4_ARVALID;
	sc_signal<bool> M0_AXI4_ARREADY;
	sc_signal<uint32_t> M0_AXI4_RID;
	sc_signal<uint64_t> M0_AXI4_RDATA;
	sc_signal<uint32_t> M0_AXI4_RRESP;
	sc_signal<bool> M0_AXI4_RLAST;
	sc_signal<bool> M0_AXI4_RVALID;
	sc_signal<bool> M0_AXI4_RREADY;
	// AXI4 Master 1
	sc_signal<uint32_t> M1_AXI4_AWID;
	sc_signal<uint64_t> M1_AXI4_AWADDR;
	sc_signal<uint32_t> M1_AXI4_AWLEN;
	sc_signal<uint32_t> M1_AXI4_AWSIZE;
	sc_signal<uint32_t> M1_AXI4_AWBURST;
	sc_signal<bool> M1_AXI4_AWLOCK;
	sc_signal<uint32_t> M1_AXI4_AWCACHE;
	sc_signal<uint32_t> M1_AXI4_AWPROT;
	sc_signal<bool> M1_AXI4_AWVALID;
	sc_signal<bool> M1_AXI4_AWREADY;
	sc_signal<uint64_t> M1_AXI4_WDATA;
	sc_signal<uint32_t> M1_AXI4_WSTRB;
	sc_signal<bool> M1_AXI4_WLAST;
	sc_signal<bool> M1_AXI4_WVALID;
	sc_signal<bool> M1_AXI4_WREADY;
	sc_signal<uint32_t> M1_AXI4_BID;
	sc_signal<uint32_t> M1_AXI4_BRESP;
	sc_signal<bool> M1_AXI4_BVALID;
	sc_signal<bool> M1_AXI4_BREADY;
	sc_signal<uint32_t> M1_AXI4_ARID;
	sc_signal<uint64_t> M1_AXI4_ARADDR;
	sc_signal<uint32_t> M1_AXI4_ARLEN;
	sc_signal<uint32_t> M1_AXI4_ARSIZE;
	sc_signal<uint32_t> M1_AXI4_ARBURST;
	sc_signal<bool> M1_AXI4_ARLOCK;
	sc_signal<uint32_t> M1_AXI4_ARCACHE;
	sc_signal<uint32_t> M1_AXI4_ARPROT;
	sc_signal<bool> M1_AXI4_ARVALID;
	sc_signal<bool> M1_AXI4_ARREADY;
	sc_signal<uint32_t> M1_AXI4_RID;
	sc_signal<uint64_t> M1_AXI4_RDATA;
	sc_signal<uint32_t> M1_AXI4_RRESP;
	sc_signal<bool> M1_AXI4_RLAST;
	sc_signal<bool> M1_AXI4_RVALID;
	sc_signal<bool> M1_AXI4_RREADY;
};
