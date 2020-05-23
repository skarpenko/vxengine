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
 * Page table examination for user space
 */

#ifndef __PGMAP_H__
#define __PGMAP_H__

#include <stdio.h>
#include <string.h>
#include <unistd.h>


typedef unsigned long long phys_addr_t;	/* Physical address */
typedef unsigned long virt_addr_t;	/* Virtual address */

/* Page information */
typedef union {
	struct {
		uint64_t pfn	: 55;	/* Page frame number */
		uint64_t sfd	: 1;	/* PTE is soft-dirty */
		uint64_t excl	: 1;	/* Page exclusively mapped */
		uint64_t __zero	: 4;	/* Zero */
		uint64_t fpsa	: 1;	/* Page is file-page or shared-anon */
		uint64_t swpd	: 1;	/* Page swapped */
		uint64_t pr	: 1;	/* Page present */
	};
	struct {
		uint64_t swt	: 5;	/* Swap type if swapped */
		uint64_t swo	: 50;	/* Swap offset if swapped */
		uint64_t __ign	: 9;	/* Ignored */
	};
	uint64_t v64;
} pgmap_pi_t;

/* Page mapper */
struct pgmap {
	FILE *fh;			/* File handle for "pagemap" file */
	unsigned pg_size;		/* Page size */
	unsigned pg_mask;		/* Page mask */
	virt_addr_t cache_virt;		/* Last translated virtual page */
	phys_addr_t cache_phys;		/* Last translation result */
};


/**
 * __pgmap_init - init page mapper (internally used)
 *
 * @param pgmap page mapper structure
 * @param pagemap path to "pagemap" of a process
 * @return 0 on success and -1 otherwise
 */
static inline
int __pgmap_init(struct pgmap *pgmap, const char* pagemap)
{
	/* Open "pagemap" file of a process */
	pgmap->fh = fopen(pagemap, "rb");
	if(!pgmap->fh)
		return -1;

	pgmap->pg_size = getpagesize();
	pgmap->pg_mask = pgmap->pg_size - 1;
	pgmap->cache_virt = pgmap->cache_phys = 0;

	return 0;
}


/**
 * pgmap_init - init page mapper for a specific process
 *
 * @param pgmap page mapper structure
 * @param pid process id
 * @return 0 on success and -1 otherwise
 */
static inline
int pgmap_init(struct pgmap *pgmap, pid_t pid)
{
	char pagemap_path[64];
	snprintf(pagemap_path, sizeof(pagemap_path), "/proc/%d/pagemap", pid);
	return __pgmap_init(pgmap, pagemap_path);
}


/**
 * pgmap_init_self - init page mapper for current process
 *
 * @param pgmap page mapper structure
 * @param pid process id
 * @return 0 on success and -1 otherwise
 */
static inline
int pgmap_init_self(struct pgmap *pgmap)
{
	return __pgmap_init(pgmap, "/proc/self/pagemap");
}


/**
 * pgmap_deinit - de-init page mapper
 *
 * @param pgmap page mapper structure
 */
static inline
void pgmap_deinit(struct pgmap *pgmap)
{
	fclose(pgmap->fh);
}


/**
 * pgmap_get_pi - get page information
 *
 * @param pgmap page mapper structure
 * @param va virtual address for translation
 * @param pi page information
 * @return 0 on success and -1 otherwise
 */
static inline
int pgmap_get_pi(struct pgmap *pgmap, void *va, pgmap_pi_t *pi)
{
	/* Offset of a page info entry */
	long offs = (long)((virt_addr_t)va / pgmap->pg_size * sizeof(*pi));
	size_t r;

	fseek(pgmap->fh, offs, SEEK_SET);

	r = fread(pi, sizeof(*pi), 1, pgmap->fh);

	return r == 1 ? 0 : -1;
}


/**
 * pgmap_get_page_addr - get page address (requires root privileges)
 *
 * @param pgmap page mapper structure
 * @param va virtual address for translation
 * @param pa physical address of a page
 * @return 0 on success and -1 otherwise
 */
static inline
int pgmap_get_page_addr(struct pgmap *pgmap, void *va, phys_addr_t *pa)
{
	pgmap_pi_t pi;
	int ret;

	*pa = 0;

	ret = pgmap_get_pi(pgmap, va, &pi);
	if(ret)
		return ret;

	if(pi.pr && !pi.swpd) {
		*pa = pi.pfn * pgmap->pg_size;
		return 0;
	}

	return -1;
}


/**
 * pgmap_virt_to_phys - translate virtual to physical address
 * (requires root privileges)
 *
 * @param pgmap page mapper structure
 * @param va virtual address for translation
 * @param pa physical address
 * @return 0 on success and -1 otherwise
 */
static inline
int pgmap_virt_to_phys(struct pgmap *pgmap, void *va, phys_addr_t *pa)
{
	virt_addr_t virt_page = (virt_addr_t)va & ~pgmap->pg_mask;
	int ret = 0;
	phys_addr_t phys_page;

	*pa = 0;

	/* Check if this translation was cached */
	if(pgmap->cache_virt != virt_page) {
		/* Translate and store into cache */
		ret = pgmap_get_page_addr(pgmap, va, &phys_page);
		if(!ret) {
			pgmap->cache_virt = virt_page;
			pgmap->cache_phys = phys_page;
		}
	} else {
		phys_page = pgmap->cache_phys;
	}

	if(ret)
		return ret;

	/* Physical address of data pointed by virtual address */
	*pa = phys_page + ((virt_addr_t)va & pgmap->pg_mask);

	return 0;
}


#endif /* __PGMAP_H__ */
