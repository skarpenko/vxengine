/*
 * Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
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
 * A simple signs of life test
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>


/* HPS2FPGA AXI Bridge */
#define AXIBRDG_IOBASE	0xC0000000

/* On-chip RAM Module */
#define OCRAM_IOBASE	0xFFFF0000
#define OCRAM_SIZE	0x10000

/* Control registers */
#define REG_ID		0 /* HW ID (r/o) */
#define REG_CTRL	1 /* Control (r/w) */
#define REG_STATUS	2 /* Status (r/o) */
#define REG_INTR_ACT	3 /* Active interrupts (r/w) */
#define REG_INTR_MSK	4 /* Interrupts mask (r/w) */
#define REG_INTR_RAW	5 /* Raw interrupts (r/o) */
#define REG_PGM_ADDR_LO	6 /* Program address /low/ (r/w) */
#define REG_PGM_ADDR_HI	7 /* Program address /high/ (r/w) */
#define REG_START	8 /* Start program execution (w/o) */

/* Register flags */
#define STAT_BUSY_MASK		0x00000001
#define INTR_COMPLETED_MASK	0x00000001
#define INTR_ERR_FETCH_MASK	0x00000002
#define INTR_ERR_INSTR_MASK	0x00000004
#define INTR_ERR_DATA_MASK	0x00000008


/* Test program */
uint64_t prog[] = {
	0x400000003f800000,	/* setacc vpu0, th0, 1.0        */
	0x700000003fffc400,	/* setrd  vpu0, th0, 0xffff1000 */
	0x5000000000000001,	/* seten  vpu0, th0, set        */
	0x4008000040000000,	/* setacc vpu0, th1, 2.0        */
	0x700800003fffc401,	/* setrd  vpu0, th1, 0xffff1004 */
	0x5008000000000001,	/* seten  vpu0, th1, set        */
	0x4010000040400000,	/* setacc vpu0, th2, 3.0        */
	0x701000003fffc402,	/* setrd  vpu0, th2, 0xffff1008 */
	0x5010000000000001,	/* seten  vpu0, th2, set        */
	0x4018000040800000,	/* setacc vpu0, th3, 4.0        */
	0x701800003fffc403,	/* setrd  vpu0, th3, 0xffff100C */
	0x5018000000000001,	/* seten  vpu0, th3, set        */
	0x8800000000000000,	/* store                        */
	0x0800000000000003	/* sync stop, int               */
};


volatile uint32_t *iomem;	/* MMIO base (4KB) */
volatile char *ocram;		/* On-chip RAM base*/
volatile float *dma_dest;	/* DMA destination area base */


void print_regs()
{
	uint32_t r;

	printf("REG_ID          = %08x\n", iomem[REG_ID]);
	printf("REG_CTRL        = %08x\n", iomem[REG_CTRL]);
	r = iomem[REG_STATUS];
	printf("REG_STATUS      = %08x", r);
	if(r & STAT_BUSY_MASK)
		printf(" (busy)\n");
	else
		printf("\n");
	r = iomem[REG_INTR_ACT];
	printf("REG_INTR_ACT    = %08x", r);
	if(r) {
		printf(" (");
		if(r & INTR_COMPLETED_MASK)
			printf(" completed");
		if(r & INTR_ERR_FETCH_MASK)
			printf(" fetch_err");
		if(r & INTR_ERR_INSTR_MASK)
			printf(" instr_err");
		if(r & INTR_ERR_DATA_MASK)
			printf(" data_err");
		printf(" )\n");
	} else
		printf("\n");
	r = iomem[REG_INTR_MSK];
	printf("REG_INTR_MSK    = %08x", r);
	if(r) {
		printf(" (");
		if(r & INTR_COMPLETED_MASK)
			printf(" completed");
		if(r & INTR_ERR_FETCH_MASK)
			printf(" fetch_err");
		if(r & INTR_ERR_INSTR_MASK)
			printf(" instr_err");
		if(r & INTR_ERR_DATA_MASK)
			printf(" data_err");
		printf(" )\n");
	} else
		printf("\n");
	r = iomem[REG_INTR_RAW];
	printf("REG_INTR_RAW    = %08x", r);
	if(r) {
		printf(" (");
		if(r & INTR_COMPLETED_MASK)
			printf(" completed");
		if(r & INTR_ERR_FETCH_MASK)
			printf(" fetch_err");
		if(r & INTR_ERR_INSTR_MASK)
			printf(" instr_err");
		if(r & INTR_ERR_DATA_MASK)
			printf(" data_err");
		printf(" )\n");
	} else
		printf("\n");
	printf("REG_PGM_ADDR_LO = %08x\n", iomem[REG_PGM_ADDR_LO]);
	printf("REG_PGM_ADDR_HI = %08x\n", iomem[REG_PGM_ADDR_HI]);
}


int main()
{
	int fd;
	void *va1, *va2;

	fd = open("/dev/mem", O_RDWR | O_SYNC);
	if(fd < 0) {
		printf("Failed to open /dev/mem\n");
		return -1;
	}

	va1 = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, AXIBRDG_IOBASE);
	if(va1 == MAP_FAILED) {
		close(fd);
		printf("Failed to map HPS2FPGA AXI bridge I/O region.\n");
		return -1;
	}

	va2 = mmap(NULL, OCRAM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, OCRAM_IOBASE);
	if(va2 == MAP_FAILED) {
		munmap(va1, 4096);
		close(fd);
		printf("Failed to map on-chip RAM module I/O region.\n");
		return -1;
	}

	iomem = (volatile uint32_t*)va1;
	ocram = (volatile char*)va2;
	dma_dest = (volatile float*)&ocram[0x1000];

	printf("! Registers before start:\n");
	print_regs();
	printf("\n");

	/* Run short test program from on-chip RAM */
	dma_dest[0] = 0.0;
	dma_dest[1] = 0.0;
	dma_dest[2] = 0.0;
	dma_dest[3] = 0.0;
	dma_dest[4] = 0.0;
	memcpy((char*)ocram, prog, sizeof(prog));

	iomem[REG_PGM_ADDR_LO] = OCRAM_IOBASE;
	iomem[REG_PGM_ADDR_HI] = 0;

	iomem[REG_START] = 0;

	sleep(1);	/* Wait */

	printf("! Registers after completion:\n");
	print_regs();
	printf("\n");

	iomem[REG_INTR_ACT] = iomem[REG_INTR_ACT]; /* Acknowledge interrupts */

	printf("! Registers after interrupt ack:\n");
	print_regs();
	printf("\n");

	printf("Results:\n");
	printf("0: 1.0 == %f (%s)\n", dma_dest[0], 1.0 == dma_dest[0] ? "PASS" : "FAIL");
	printf("1: 2.0 == %f (%s)\n", dma_dest[1], 2.0 == dma_dest[1] ? "PASS" : "FAIL");
	printf("2: 3.0 == %f (%s)\n", dma_dest[2], 3.0 == dma_dest[2] ? "PASS" : "FAIL");
	printf("3: 4.0 == %f (%s)\n", dma_dest[3], 4.0 == dma_dest[3] ? "PASS" : "FAIL");
	printf("4: 0.0 == %f (%s)\n", dma_dest[4], 0.0 == dma_dest[4] ? "PASS" : "FAIL");

	/* Release resources */
	munmap(va2, OCRAM_SIZE);
	munmap(va1, 4096);
	close(fd);

	return 0;
}
