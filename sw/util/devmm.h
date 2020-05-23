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
 * Access to memory-mapped device registers from user space
 */

#ifndef __DEVMM_H__
#define __DEVMM_H__

#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>


typedef unsigned long long dev_addr_t;	/* Device address type */

/* Memory-mapped device */
struct devmm {
	int fd;		/* File descriptor */
	dev_addr_t pa;	/* Physical base of I/O region */
	dev_addr_t sz;	/* I/O region size  */
	void *va;	/* Mapped virtual address */
};


/**
 * devmm_init - init memory-mapped device
 *
 * @param dev device structure
 * @param mmio_base I/O region base address
 * @param mmio_size I/O region size
 * @return 0 on success and -1 otherwise
 */
static inline
int devmm_init(struct devmm *dev, dev_addr_t mmio_base, dev_addr_t mmio_size)
{
	dev->pa = mmio_base;
	dev->sz = mmio_size;

	/* Open memory file (requires root privileges) */
	dev->fd = open("/dev/mem", O_RDWR | O_SYNC);
	if(dev->fd < 0)
		return -1;

	/* Map I/O region */
	dev->va = mmap(NULL, dev->sz, PROT_READ | PROT_WRITE, MAP_SHARED,
		dev->fd, dev->pa);
	if(dev->va == MAP_FAILED) {
		close(dev->fd);
		dev->fd = -1;
		return -1;
	}

	return 0;
}


/**
 * devmm_deinit - de-init memory mapped-device structure
 * @param dev device structure
 * @return 0 on success and -1 otherwise
 */
static inline
int devmm_deinit(struct devmm *dev)
{
	if(dev->fd < 0)
		return -1;

	/* Unmap I/O region */
	if(munmap(dev->va, dev->sz) < 0)
		return -1;

	/* Close file descriptor */
	if(close(dev->fd) < 0)
		return -1;

	dev->fd = -1;
	dev->va = (void*)0;
	dev->pa = 0;
	dev->sz = 0;

	return 0;
}


/**
 * devmm_rreg32 - read 32-bit register
 *
 * @param dev device structure
 * @param offs byte offset of a register
 * @return register value
 */
static inline
uint32_t devmm_rreg32(struct devmm *dev, unsigned offs)
{
	volatile uint32_t *reg = (volatile uint32_t*)((char*)dev->va + offs);
	return *reg;
}


/**
 * devmm_wreg32 - write 32-bit register
 *
 * @param dev device structure
 * @param offs byte offset of a register
 * @param val value to write
 */
static inline
void devmm_wreg32(struct devmm *dev, unsigned offs, uint32_t val)
{
	volatile uint32_t *reg = (volatile uint32_t*)((char*)dev->va + offs);
	*reg = val;
}


/**
 * devmm_rreg64 - read 64-bit register
 *
 * @param dev device structure
 * @param offs byte offset of a register
 * @return register value
 */
static inline
uint64_t devmm_rreg64(struct devmm *dev, unsigned offs)
{
	volatile uint64_t *reg = (volatile uint64_t*)((char*)dev->va + offs);
	return *reg;
}


/**
 * devmm_wreg64 - write 64-bit register
 *
 * @param dev device structure
 * @param offs byte offset of a register
 * @param val value to write
 */
static inline
void devmm_wreg64(struct devmm *dev, unsigned offs, uint64_t val)
{
	volatile uint64_t *reg = (volatile uint64_t*)((char*)dev->va + offs);
	*reg = val;
}


#endif /* __DEVMM_H__ */
