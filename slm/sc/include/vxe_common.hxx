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
 * VxEngine common constants
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

} // namespace vxe
