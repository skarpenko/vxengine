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
 * VxE registers definitions
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
		static constexpr unsigned REG_FAULT_VPU_MASK0		= 13;	// Faulted VPUs mask (r/o)
		static constexpr unsigned REGS_NUMBER			= 14;	// Registers number
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
		static constexpr unsigned REG_FAULT_VPU_MASK0		= regi::REG_FAULT_VPU_MASK0 << 2u;
		static constexpr unsigned REGS_NUMBER			= regi::REGS_NUMBER;
	} // namespace rego

	// Register valid bit masks
	namespace regm {
		static constexpr unsigned REG_ID			= 0xFFFFFFFF;
		static constexpr unsigned REG_CTRL			= 0x00000001;
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
		static constexpr unsigned REG_FAULT_VPU_MASK0		= 0x00000003;
		static constexpr unsigned REGS_NUMBER			= regi::REGS_NUMBER;
	} // namespace regm

	// Register bit fields
	namespace bits {

		// Control register
		namespace REG_CTRL {
			static constexpr unsigned CU_MAS_SEL_MASK	= 0x00000001;
			static constexpr unsigned CU_MAS_SEL_SHIFT	= 0x00000000;
		} // namespace REG_CTRL

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

		// Faulted VPUs mask
		namespace REG_FAULT_VPU_MASK0 {
			static constexpr unsigned FAULTED_VPU0_MASK	= 0x00000001;
			static constexpr unsigned FAULTED_VPU0_SHIFT	= 0x00000000;
			static constexpr unsigned FAULTED_VPU1_MASK	= 0x00000002;
			static constexpr unsigned FAULTED_VPU1_SHIFT	= 0x00000001;
		} // namespace REG_FAULT_VPU_MASK0

	} // namespace bits

} // namespace vxe
