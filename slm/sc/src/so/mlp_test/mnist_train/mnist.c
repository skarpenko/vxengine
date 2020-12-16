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
 * MNIST dataset loader
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mnist.h"


static inline uint32_t mnist_bswap(uint32_t a)
{
	a = ((a & 0x000000FF) << 24) |
	    ((a & 0x0000FF00) << 8) |
	    ((a & 0x00FF0000) >> 8) |
	    ((a & 0xFF000000) >> 24);
	return a;
}

void* mnist_load_file(const char *file)
{
	FILE *fh;
	long fsz;
	void *data;

	fh = fopen(file, "rb");
	if(fh == NULL)
		return NULL;

	fseek(fh, 0, SEEK_END);
	fsz = ftell(fh);
	fseek(fh, 0, SEEK_SET);

	data = malloc(fsz);
	if(data == NULL) {
		fclose(fh);
		return NULL;
	}

	if(fread(data, 1, fsz, fh) != fsz) {
		fclose(fh);
		free(data);
		return NULL;
	}

	fclose(fh);

	return data;
}

struct mnist_images *mnist_load_images(const char *file)
{
	struct mnist_images *images =
		(struct mnist_images*)mnist_load_file(file);
	if(images == NULL)
		return NULL;

	images->magic = mnist_bswap(images->magic);
	images->num_images = mnist_bswap(images->num_images);
	images->width = mnist_bswap(images->width);
	images->height = mnist_bswap(images->height);

	if(images->magic != 0x00000803 || images->width != 28 ||
	   images->height != 28 || images->num_images == 0)
	{
		free(images);
		return NULL;
	}

	return images;
}

struct mnist_labels *mnist_load_labels(const char *file)
{
	struct mnist_labels *labels =
		(struct mnist_labels*)mnist_load_file(file);
	if(labels == NULL)
		return NULL;

	labels->magic = mnist_bswap(labels->magic);
	labels->num_labels = mnist_bswap(labels->num_labels);

	if(labels->magic != 0x00000801 || labels->num_labels == 0)
	{
		free(labels);
		return NULL;
	}

	return labels;
}

struct mnist_double_image *mnist_images_convert(struct mnist_images *images, double min, double max)
{
	struct mnist_double_image *fimages;
	uint32_t i, j, k;

	fimages = (struct mnist_double_image *)malloc(
		images->num_images * sizeof(struct mnist_double_image));
	if(fimages == NULL)
		return NULL;

	for(k = 0; k < images->num_images; ++k) {
		for(i = 0; i < 28; ++i)
			for(j = 0; j < 28; ++j)
				fimages[k].data[i][j] =
					((float)images->images[k].data[i][j] * (max - min)) / 255.0 + min;
	}

	return fimages;
}

struct mnist_double_label *mnist_labels_convert(struct mnist_labels *labels, double max)
{
	struct mnist_double_label *flabels;
	uint32_t k;

	flabels = (struct mnist_double_label *)malloc(
		labels->num_labels * sizeof(struct mnist_double_label));
	if(flabels == NULL)
		return NULL;
	memset(flabels, 0, labels->num_labels * sizeof(struct mnist_double_label));

	for(k = 0; k < labels->num_labels; ++k)
		flabels[k].data[labels->labels[k]] = max;

	return flabels;
}
