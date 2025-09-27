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
 * Fake CPU software interface
 */

#ifndef _VXE_TOP_VL_FAKE_CPU_API_H_
#define _VXE_TOP_VL_FAKE_CPU_API_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


/* Application entry point name */
#define FAKE_CPU_ENTRY_NAME	"fake_cpu_entry"

/* Application entry type */
typedef int (*fake_cpu_entry_t)(struct fake_cpu_api *cpu_api);


/* Direct memory interface info */
struct fake_cpu_dmi {
	void *ptr;	/* Pointer to memory */
	uint64_t start;	/* Start address value */
	uint64_t end;	/* End address value */
};


/* CPU/Application interface */
struct fake_cpu_api {
	void *cpuid;

	/**
	 * Wait for clock posedge
	 * @param cpuid CPU interface to use
	 */
	void (*wait)(void *cpuid);

	/**
	 * Wait for N clock cycles
	 * @param cpuid CPU interface to use
	 * @param cycles number of cycles
	 */
	void (*wait_cycles)(void *cpuid, unsigned cycles);

	/**
	 * Wait for interrupt
	 * @param cpuid CPU interface to use
	 */
	void (*wait_intr)(void *cpuid);

	/**
	 * MMIO 32-bit register read
	 * @param cpuid CPU interface to use
	 * @param addr I/O address
	 * @return register value
	 */
	uint32_t (*mmio_rreg32)(void *cpuid, uint64_t addr);

	/**
	 * MMIO 32-bit register write
	 * @param cpuid CPU interface to use
	 * @param addr I/O address
	 * @param value value to write
	 */
	void (*mmio_wreg32)(void *cpuid, uint64_t addr, uint32_t value);

	/**
	 * Get direct memory interface info
	 * @param cpuid CPU interface to use
	 * @param mi memory info structure
	 */
	void (*get_dmi)(void *cpuid, struct fake_cpu_dmi *dmi);
};


#ifdef FAKE_CPU_API_SHORTCUTS
/**
 * Shortcut macros
 * Require global define:
 * #define FAKE_CPU_API <global_cpu_api_var>
 */

#define wait()	\
	FAKE_CPU_API->wait(FAKE_CPU_API->cpuid)

#define wait_cycles(cycles)	\
	FAKE_CPU_API->wait_cycles(FAKE_CPU_API->cpuid, (cycles))

#define wait_intr()	\
	FAKE_CPU_API->wait_intr(FAKE_CPU_API->cpuid)

#define mmio_rreg32(addr)	\
	FAKE_CPU_API->mmio_rreg32(FAKE_CPU_API->cpuid, (addr))

#define mmio_wreg32(addr, value)	\
	FAKE_CPU_API->mmio_wreg32(FAKE_CPU_API->cpuid, (addr), (value))

#define get_dmi(dmi)	\
	FAKE_CPU_API->get_dmi(FAKE_CPU_API->cpuid, (dmi))

#endif /* FAKE_CPU_API_SHORTCUTS */


#ifdef __cplusplus
}
#endif

#endif /* _VXE_TOP_VL_FAKE_CPU_API_H_ */
