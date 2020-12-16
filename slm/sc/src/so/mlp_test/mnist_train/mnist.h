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

#ifndef MNIST_MNIST_H
#define MNIST_MNIST_H

#include <stdint.h>

/** MNIST data structures **/

struct mnist_image {
	uint8_t data[28][28];
};

struct mnist_images {
	uint32_t magic;	/* 0x00000803 */
	uint32_t num_images;
	uint32_t width;
	uint32_t height;
	struct mnist_image images[];
};

struct mnist_labels {
	uint32_t magic;	/* 0x00000801 */
	uint32_t num_labels;
	uint8_t labels[];
};

struct mnist_double_image {
	double data[28][28];
};

struct mnist_double_label {
	double data[10];
};


/**
 * Load file into memory
 * @param file path to a file
 * @return pointer to memory location or NULL
 */
void* mnist_load_file(const char *file);

/**
 * Load MNIST images
 * @param file path to MNIST images file
 * @return pointer to loaded images
 */
struct mnist_images *mnist_load_images(const char *file);

/**
 * Load MNIST labels
 * @param file path to MNIST labels file
 * @return pointer to loaded labels
 */
struct mnist_labels *mnist_load_labels(const char *file);

/**
 * Convert MNIST images to a double precision format
 * @param images source MNIST images
 * @param min minimum value
 * @param max maximum value
 * @return pointer to double precision images
 */
struct mnist_double_image *mnist_images_convert(struct mnist_images *images, double min, double max);

/**
 * Convert MNIST labels to a double precision format
 * @param labels source MNIST labels
 * @param max maximum value
 * @return pointer to double precision labels
 */
struct mnist_double_label *mnist_labels_convert(struct mnist_labels *labels, double max);


#endif /* MNIST_MNIST_H */
