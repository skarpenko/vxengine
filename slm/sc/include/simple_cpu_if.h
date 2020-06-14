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
 * Simple CPU software interface
 */

#ifndef _VXMODEL_SIMPLE_CPU_IF_H_
#define _VXMODEL_SIMPLE_CPU_IF_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


/* Application entry point name */
#define SIMPLE_CPU_ENTRY_NAME	"simple_cpu_entry"

/* Application entry type */
typedef int (*simple_cpu_entry_t)(struct simple_cpu_if *cpu_if);


/* Direct memory interface info */
struct simple_cpu_dmi {
	void *ptr;	/* Pointer to memory */
	uint64_t start;	/* Start address value */
	uint64_t end;	/* End address value */
};


/* CPU/Application interface */
struct simple_cpu_if {
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
	 * @param dmi DMI info
	 * @return 0 if DMI is not supported
	 */
	int (*get_dmi)(void *cpuid, struct simple_cpu_dmi *dmi);
};


/**
 * Shortcut macros
 * Require global define:
 * #define SIMPLE_CPU_IF <global_cpu_if_var>
 */

#define mmio_rreg32(addr)	\
	SIMPLE_CPU_IF->mmio_rreg32(SIMPLE_CPU_IF->cpuid, (addr))

#define mmio_wreg32(addr, value)	\
	SIMPLE_CPU_IF->mmio_wreg32(SIMPLE_CPU_IF->cpuid, (addr), (value))


#ifdef __cplusplus
}
#endif

#endif /* _VXMODEL_SIMPLE_CPU_IF_H_ */
