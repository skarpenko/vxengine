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
		static constexpr unsigned REG_FAULT_INSTR_ADDR_LO	= 8;	// Faulted instr. address /low/ (r/o)
		static constexpr unsigned REG_FAULT_INSTR_ADDR_HI	= 9;	// Faulted instr. address /high/ (r/o)
		static constexpr unsigned REG_FAULT_INSTR_LO		= 10;	// Faulted instruction /low/ (r/o)
		static constexpr unsigned REG_FAULT_INSTR_HI		= 11;	// Faulted instruction /high/ (r/o)
		static constexpr unsigned REGS_NUMBER			= 12;	// Registers number
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
		static constexpr unsigned REG_INTR_ACT			= 0x00000001;
		static constexpr unsigned REG_INTR_MSK			= 0x00000001;
		static constexpr unsigned REG_INTR_RAW			= 0x00000001;
		static constexpr unsigned REG_PGM_ADDR_LO		= 0xFFFFFFFF;
		static constexpr unsigned REG_PGM_ADDR_HI		= 0xFFFFFFFF;
		static constexpr unsigned REG_FAULT_INSTR_ADDR_LO	= 0xFFFFFFFF;
		static constexpr unsigned REG_FAULT_INSTR_ADDR_HI	= 0xFFFFFFFF;
		static constexpr unsigned REG_FAULT_INSTR_LO		= 0xFFFFFFFF;
		static constexpr unsigned REG_FAULT_INSTR_HI		= 0xFFFFFFFF;
		static constexpr unsigned REGS_NUMBER			= regi::REGS_NUMBER;
	} // namespace regm

	// Register bit fields
	namespace bits {

		// Control register
		namespace REG_CTRL {
			static constexpr unsigned START_MASK	= 0x00000001;
			static constexpr unsigned START_SHIFT	= 0x00000000;
		} // namespace REG_CTRL

		// Active interrupts register
		namespace REG_INTR_ACT {
			static constexpr unsigned INTR0_MASK	= 0x00000001;
			static constexpr unsigned INTR0_SHIFT	= 0x00000000;
		} // namespace REG_INTR_ACT

		// Interrupt masks register
		namespace REG_INTR_MSK {
			static constexpr unsigned IMSK0_MASK	= 0x00000001;
			static constexpr unsigned IMSK0_SHIFT	= 0x00000000;
		} // namespace REG_INTR_MSK

		// Raw interrupts register
		namespace REG_INTR_RAW {
			static constexpr unsigned INTR0_MASK	= 0x00000001;
			static constexpr unsigned INTR0_SHIFT	= 0x00000000;
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
		};

		// SYNC - Synchronize - Wait for completion of all previous operations
		union sync {
			static constexpr unsigned OP = 0x18;	// Opcode value
			struct {
				uint64_t intr	: 1;	// Send interrupt
				uint64_t _z0	: 58;	// Must be zero
				uint64_t op	: 5;	// Opcode
			};
			uint64_t u64;

			sync() : _z0(0), op(OP) {}
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
