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
 * VxEngine common constants and data structures
 */

#include <cstdint>
#pragma once


namespace vxe {

	// Hardware ID
	static constexpr uint32_t VXENGINE_ID	= 0xFEFEFAFA;

	// Register indexes
	namespace regi {
		static constexpr unsigned REG_ID			= 0;	// HW ID (r/o)
		static constexpr unsigned REG_CTRL			= 1;	// Control (r/w)
		static constexpr unsigned REG_STATUS			= 2;	// Status (r/o)
		static constexpr unsigned REG_INTR_ACT			= 3;	// Active interrupts (r/w)
		static constexpr unsigned REG_INTR_MSK			= 4;	// Interrupts mask (r/w)
		static constexpr unsigned REG_INTR_RAW			= 5;	// Raw interrupts (r/o)
		static constexpr unsigned REG_PGM_ADDR_LO		= 6;	// Program address /low/ (r/w)
		static constexpr unsigned REG_PGM_ADDR_HI		= 7;	// Program address /high/ (r/w)
		static constexpr unsigned REG_START			= 8;	// Start program execution (w/o)
		static constexpr unsigned REG_FAULT_INSTR_ADDR_LO	= 9;	// Faulted instr. address /low/ (r/o)
		static constexpr unsigned REG_FAULT_INSTR_ADDR_HI	= 10;	// Faulted instr. address /high/ (r/o)
		static constexpr unsigned REG_FAULT_INSTR_LO		= 11;	// Faulted instruction /low/ (r/o)
		static constexpr unsigned REG_FAULT_INSTR_HI		= 12;	// Faulted instruction /high/ (r/o)
		static constexpr unsigned REGS_NUMBER			= 13;	// Registers number
	} // namespace regi

	// Register offsets
	namespace rego {
		static constexpr unsigned REG_ID			= regi::REG_ID << 2u;
		static constexpr unsigned REG_CTRL			= regi::REG_CTRL << 2u;
		static constexpr unsigned REG_STATUS			= regi::REG_STATUS << 2u;
		static constexpr unsigned REG_INTR_ACT			= regi::REG_INTR_ACT << 2u;
		static constexpr unsigned REG_INTR_MSK			= regi::REG_INTR_MSK << 2u;
		static constexpr unsigned REG_INTR_RAW			= regi::REG_INTR_RAW << 2u;
		static constexpr unsigned REG_PGM_ADDR_LO		= regi::REG_PGM_ADDR_LO << 2u;
		static constexpr unsigned REG_PGM_ADDR_HI		= regi::REG_PGM_ADDR_HI << 2u;
		static constexpr unsigned REG_START			= regi::REG_START << 2u;
		static constexpr unsigned REG_FAULT_INSTR_ADDR_LO	= regi::REG_FAULT_INSTR_ADDR_LO << 2u;
		static constexpr unsigned REG_FAULT_INSTR_ADDR_HI	= regi::REG_FAULT_INSTR_ADDR_HI << 2u;
		static constexpr unsigned REG_FAULT_INSTR_LO		= regi::REG_FAULT_INSTR_LO << 2u;
		static constexpr unsigned REG_FAULT_INSTR_HI		= regi::REG_FAULT_INSTR_HI << 2u;
		static constexpr unsigned REGS_NUMBER			= regi::REGS_NUMBER;
	} // namespace rego

	// Register valid bit masks
	namespace regm {
		static constexpr unsigned REG_ID			= 0xFFFFFFFF;
		static constexpr unsigned REG_CTRL			= 0x0000000F;
		static constexpr unsigned REG_STATUS			= 0x0000000F;
		static constexpr unsigned REG_INTR_ACT			= 0x0000000F;
		static constexpr unsigned REG_INTR_MSK			= 0x0000000F;
		static constexpr unsigned REG_INTR_RAW			= 0x0000000F;
		static constexpr unsigned REG_PGM_ADDR_LO		= 0xFFFFFFF8;
		static constexpr unsigned REG_PGM_ADDR_HI		= 0x000000FF;
		static constexpr unsigned REG_START			= 0x00000000;
		static constexpr unsigned REG_FAULT_INSTR_ADDR_LO	= 0xFFFFFFFF;
		static constexpr unsigned REG_FAULT_INSTR_ADDR_HI	= 0x000000FF;
		static constexpr unsigned REG_FAULT_INSTR_LO		= 0xFFFFFFFF;
		static constexpr unsigned REG_FAULT_INSTR_HI		= 0x000000FF;
		static constexpr unsigned REGS_NUMBER			= regi::REGS_NUMBER;
	} // namespace regm

	// Register bit fields
	namespace bits {

		// Status register
		namespace REG_STATUS {
			static constexpr unsigned BUSY_MASK	= 0x00000001;
			static constexpr unsigned BUSY_SHIFT	= 0x00000000;
		} // namespace REG_STATUS

		// Active interrupts register
		namespace REG_INTR_ACT {
			static constexpr unsigned COMPLETED_MASK	= 0x00000001;
			static constexpr unsigned COMPLETED_SHIFT	= 0x00000000;
			static constexpr unsigned ERR_FETCH_MASK	= 0x00000002;
			static constexpr unsigned ERR_FETCH_SHIFT	= 0x00000001;
			static constexpr unsigned ERR_INSTR_MASK	= 0x00000004;
			static constexpr unsigned ERR_INSTR_SHIFT	= 0x00000002;
			static constexpr unsigned ERR_DATA_MASK		= 0x00000008;
			static constexpr unsigned ERR_DATA_SHIFT	= 0x00000003;
		} // namespace REG_INTR_ACT

		// Interrupt masks register
		namespace REG_INTR_MSK {
			static constexpr unsigned COMPLETED_MASK	= 0x00000001;
			static constexpr unsigned COMPLETED_SHIFT	= 0x00000000;
			static constexpr unsigned ERR_FETCH_MASK	= 0x00000002;
			static constexpr unsigned ERR_FETCH_SHIFT	= 0x00000001;
			static constexpr unsigned ERR_INSTR_MASK	= 0x00000004;
			static constexpr unsigned ERR_INSTR_SHIFT	= 0x00000002;
			static constexpr unsigned ERR_DATA_MASK		= 0x00000008;
			static constexpr unsigned ERR_DATA_SHIFT	= 0x00000003;
		} // namespace REG_INTR_MSK

		// Raw interrupts register
		namespace REG_INTR_RAW {
			static constexpr unsigned COMPLETED_MASK	= 0x00000001;
			static constexpr unsigned COMPLETED_SHIFT	= 0x00000000;
			static constexpr unsigned ERR_FETCH_MASK	= 0x00000002;
			static constexpr unsigned ERR_FETCH_SHIFT	= 0x00000001;
			static constexpr unsigned ERR_INSTR_MASK	= 0x00000004;
			static constexpr unsigned ERR_INSTR_SHIFT	= 0x00000002;
			static constexpr unsigned ERR_DATA_MASK		= 0x00000008;
			static constexpr unsigned ERR_DATA_SHIFT	= 0x00000003;
		} // namespace REG_INTR_RAW

	} // namespace bits

	// Instructions
	namespace instr {

		// Generic instruction (it's not a real instruction)
		union generic {
			struct {
				uint64_t raw	: 59;	// Other bits
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			explicit generic(uint64_t _u = 0) : u64(_u) {}

			operator uint64_t() const { return u64; }
		};

		// Generic activation function instruction (it's not a real instruction)
		union generic_af {
			static constexpr unsigned OP = 0x02;	// Opcode value
			struct {
				uint64_t pl	: 51;	// Optional
				uint64_t af	: 8;	// Activation function type
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			explicit generic_af(uint64_t _u = 0) : u64(_u) {}
			generic_af(const union generic& g) : u64(g) {}

			operator uint64_t() const { return u64; }
		};

		// NOP - No Operation - used for padding
		union nop {
			static constexpr unsigned OP = 0x00;	// Opcode value
			struct {
				uint64_t _z0	: 59;	// Must be zero
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			nop() : _z0(0), op(OP) {}
			nop(const union generic& g) : u64(g) {}

			operator uint64_t() const { return u64; }
		};

		// SETACC - Set Accumulator - Set an accumulator register per thread
		union setacc {
			static constexpr unsigned OP = 0x08;	// Opcode value
			struct {
				uint64_t acc	: 32;	// Accumulator value in FP32 format
				uint64_t _z0	: 19;	// Must be zero
				uint64_t tid	: 8;	// Thread Id
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			setacc() : _z0(0), op(OP) {}
			setacc(const union generic& g) : u64(g) {}
			setacc(unsigned _tid, uint32_t _acc)
				: _z0(0), op(OP)
			{
				tid = _tid;
				acc = _acc;
			}
			setacc(unsigned _tid, float _acc)
				: _z0(0), op(OP)
			{
				// to avoid strict-aliasing rule violation
				union cvt {
					float a;
					uint32_t b;
				};
				cvt c = { .a = _acc };
				tid = _tid;
				acc = c.b;
			}

			operator uint64_t() const { return u64; }
		};

		// SETVL - Set Vector Length - Set vector length per thread
		union setvl {
			static constexpr unsigned OP = 0x09;	// Opcode value
			struct {
				uint64_t len	: 20;	// Vector length
				uint64_t _z0	: 31;	// Must be zero
				uint64_t tid	: 8;	// Thread Id
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			setvl() : _z0(0), op(OP) {}
			setvl(const union generic& g) : u64(g) {}
			setvl(unsigned _tid, unsigned _len)
				: _z0(0), op(OP)
			{
				tid = _tid;
				len = _len;
			}

			operator uint64_t() const { return u64; }
		};

		// SETRS - Set First Operand - Set first operand vector per thread
		union setrs {
			static constexpr unsigned OP = 0x0C;	// Opcode value
			struct {
				uint64_t addr	: 38;	// Upper 38-bits of 32-bit aligned address
				uint64_t _z0	: 13;	// Must be zero
				uint64_t tid	: 8;	// Thread Id
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			setrs() : _z0(0), op(OP) {}
			setrs(const union generic& g) : u64(g) {}
			setrs(unsigned _tid, uint64_t _addr)
				: _z0(0), op(OP)
			{
				tid = _tid;
				addr = _addr >> 2u;
			}

			operator uint64_t() const { return u64; }
		};

		// SETRT - Set Second Operand - Set second operand vector per thread
		union setrt {
			static constexpr unsigned OP = 0x0D;	// Opcode value
			struct {
				uint64_t addr	: 38;	// Upper 38-bits of 32-bit aligned address
				uint64_t _z0	: 13;	// Must be zero
				uint64_t tid	: 8;	// Thread Id
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			setrt() : _z0(0), op(OP) {}
			setrt(const union generic& g) : u64(g) {}
			setrt(unsigned _tid, uint64_t _addr)
				: _z0(0), op(OP)
			{
				tid = _tid;
				addr = _addr >> 2u;
			}

			operator uint64_t() const { return u64; }
		};

		// SETRD - Set Destination - Set destination storage for result
		union setrd {
			static constexpr unsigned OP = 0x0E;	// Opcode value
			struct {
				uint64_t addr	: 38;	// Upper 38-bits of 32-bit aligned address
				uint64_t _z0	: 13;	// Must be zero
				uint64_t tid	: 8;	// Thread Id
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			setrd() : _z0(0), op(OP) {}
			setrd(const union generic& g) : u64(g) {}
			setrd(unsigned _tid, uint64_t _addr)
				: _z0(0), op(OP)
			{
				tid = _tid;
				addr = _addr >> 2u;
			}

			operator uint64_t() const { return u64; }
		};

		// SETEN - Set Thread Enable - Enable or disable selected thread
		union seten {
			static constexpr unsigned OP = 0x0A;	// Opcode value
			struct {
				uint64_t en	: 1;	// Enable/disable bit
				uint64_t _z0	: 50;	// Must be zero
				uint64_t tid	: 8;	// Thread Id
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			seten() : _z0(0), op(OP) {}
			seten(const union generic& g) : u64(g) {}
			seten(unsigned _tid, bool _en)
				: _z0(0), op(OP)
			{
				tid = _tid;
				en = _en;
			}

			operator uint64_t() const { return u64; }
		};

		// PROD - Vector Product - Run enabled threads to compute vector product
		union prod {
			static constexpr unsigned OP = 0x01;	// Opcode value
			struct {
				uint64_t _z0	: 59;	// Must be zero
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			prod() : _z0(0), op(OP) {}
			prod(const union generic& g) : u64(g) {}

			operator uint64_t() const { return u64; }
		};

		// STORE - Store Result - Store result of enabled threads
		union store {
			static constexpr unsigned OP = 0x10;	// Opcode value
			struct {
				uint64_t _z0	: 59;	// Must be zero
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			store() : _z0(0), op(OP) {}
			store(const union generic& g) : u64(g) {}

			operator uint64_t() const { return u64; }
		};

		// SYNC - Synchronize - Wait for completion of all previous operations
		union sync {
			static constexpr unsigned OP = 0x18;	// Opcode value
			struct {
				uint64_t stop	: 1;	// Stop program execution
				uint64_t intr	: 1;	// Send interrupt
				uint64_t _z0	: 57;	// Must be zero
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			sync() : _z0(0), op(OP) {}
			sync(const union generic& g) : u64(g) {}
			sync(bool _stop, bool _intr)
				: _z0(0), op(OP)
			{
				stop = _stop;
				intr = _intr;
			}

			operator uint64_t() const { return u64; }
		};

		// RELU - ReLU activation - Run ReLU on accumulators of enabled threads
		union relu {
			static constexpr unsigned OP = 0x02;	// Opcode value
			static constexpr unsigned AF = 0x00;	// Activation type
			struct {
				uint64_t _z0	: 51;	// Must be zero
				uint64_t af	: 8;	// Activation function type
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			relu() : _z0(0), af(AF), op(OP) {}
			relu(const union generic& g) : u64(g) {}

			operator uint64_t() const { return u64; }
		};

		// LRELU - Leaky ReLU activation - Run leaky ReLU on accumulators of enabled threads
		union lrelu {
			static constexpr unsigned OP = 0x02;	// Opcode value
			static constexpr unsigned AF = 0x01;	// Activation type
			struct {
				uint64_t ed	: 7;	// Exponent diff / scale factor
				uint64_t _z0	: 44;	// Must be zero
				uint64_t af	: 8;	// Activation function type
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			lrelu(int e) : ed(0x7F & e), _z0(0), af(AF), op(OP) {}
			lrelu(const union generic& g) : u64(g) {}

			operator uint64_t() const { return u64; }
		};

	} // namespace instr

	/**
	 * Get bit field
	 * @tparam T register value type
	 * @param v value
	 * @param mask bit mask
	 * @param shift shift amount
	 * @return field value
	 */
	template<typename T>
	T getbits(T v, T mask, T shift)
	{
		return (v & mask) >> shift;
	}

	/**
	 * Set bit field
	 * @tparam T register value type
	 * @param v current register value
	 * @param n new field value
	 * @param mask bit mask
	 * @param shift shift amount
	 * @return updated register value
	 */
	template<typename T>
	T setbits(T v, T n, T mask, T shift)
	{
		v &= ~(mask << shift);
		v |= (n << shift) & mask;
		return v;
	}

} // namespace vxe
