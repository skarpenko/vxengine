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
 * MNIST train program for MLP test
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "enn.h"
#include "enn_train.h"
#include "mnist.h"

/*
 * MNIST DATABASE: http://yann.lecun.com/exdb/mnist/
 */


/* Parameters */
#define MNIST_IMAGE_MIN		(0.0)
#define MNIST_IMAGE_MAX		(1.0)
#define MNIST_LABEL_MAX		(1.0)
#define MNIST_LIMIT_TRAIN_DB	(100)
#define MNIST_LIMIT_TEST_DB	(100)


/* Training parameters */
#define MLP_MF		(0.9)		/* Momentum factor */
#define MLP_LR		(0.0000001)	/* Learning rate */
#define MLP_WD		(0.0)		/* Weight decay */
#define MLP_BATCH	(10)		/* Batch size */
#define MLP_EPOCHS_B	(10000)		/* Epochs per batch */
#define MLP_EPOCHS	(10)		/* Epochs */


/* MNIST train data set */
size_t mnist_ntrain_images = 0;
struct mnist_double_image *mnist_train_images = NULL;
struct mnist_double_label *mnist_train_labels = NULL;

/* MNIST test data set */
size_t mnist_ntest_images = 0;
struct mnist_double_image *mnist_test_images = NULL;
struct mnist_double_label *mnist_test_labels = NULL;

/* Paths */
const char *mnist_db_path = NULL;
const char *output_path = "./";

/** NEURAL NETWORK **/
#define MLP_NI	(28*28)		/* Number of inputs (28x28 MNIST image size) */
#define MLP_NH	(800)		/* Number of hidden neurons */
#define MLP_NO	(10)		/* Number of outputs */

/* Layers */
ENN_PROD_LAYER(mlp_prod1, MLP_NI, MLP_NH);
ENN_LRELUACT_LAYER(mlp_act1, MLP_NH, 0.0625);	/* 0.0625 -> EXPDIFF = -4 */
ENN_PROD_LAYER(mlp_prod2, MLP_NH, MLP_NO);
ENN_LRELUACT_LAYER(mlp_act2, MLP_NO, 0.0625);	/* 0.0625 -> EXPDIFF = -4 */

/* Define neural network */
ENN_NET(mlp, ENNL(mlp_prod1), ENNL(mlp_act1), ENNL(mlp_prod2), ENNL(mlp_act2));

/* Define first training layer */
ENN_MLP_TRAIN_LAYER(tr_layer1, ENNP(mlp_prod1), ENNP(mlp_act1), MLP_NI, MLP_NH, enn_mlp_lreluact_deriv);
/* Define second training layer */
ENN_MLP_TRAIN_LAYER(tr_layer2, ENNP(mlp_prod2), ENNP(mlp_act2), MLP_NH, MLP_NO, enn_mlp_lreluact_deriv);
/* Define a trainer for Multilayer Perceptron (MLP) network */
ENN_MLP_TRAINER(mlp_trainer, MLP_MF, MLP_LR, MLP_WD, enn_mlp_loss, ENNP(tr_layer1), ENNP(tr_layer2));
/** END OF NEURAL NETWORK DEFINITION **/


/* Auxiliary functions */
void release_resources();
void load_mnist(const char *mnist_path);
void mlp_train();
void mlp_test();
void mlp_save_weights();
int best_result_pos(const double *out);
int print_current_result(size_t sample, struct mnist_double_label *labels);
void enn_store_layer_weights(struct enn_prod_layer *pl, const char *path, const char *name, const char *type);
void mnist_store_images(struct mnist_double_image *images, size_t n, const char *path, const char *name,
	const char *type);
void mnist_store_labels(struct mnist_double_label *labels, size_t n, const char *path, const char *name,
			const char *type);
void mnist_save_datasets();


/* MAIN */
int main(int argc, char **argv) {
	/* Print help */
	if(argc < 2) {
		printf("MNIST train\n-----------\n");
		printf("Usage: mnist_train -mnist <dir> -out <dir><\n");
		return 0;
	}

	/* Random seed */
	srand(time(NULL));

	/* Parse command line arguments */
	for(int i = 1; i < argc; ++i) {
		if(!strcmp(argv[i], "-mnist")) {
			if(++i == argc) {
				printf("Missing -mnist argument.\n");
				return -1;
			}
			mnist_db_path = argv[i];

		} else if(!strcmp(argv[i], "-out")) {
			if(++i == argc) {
				printf("Missing -out argument.\n");
				return -1;
			}
			output_path = argv[i];
		} else {
			printf("Unknown command line argument: %s\n", argv[1]);
			return -1;
		}
	}

	if(mnist_db_path == NULL) {
		printf("MNIST DB path is missing.\n");
		return -1;
	}

	printf("MNIST : %s\n", mnist_db_path);
	printf("Output: %s\n", output_path);

	load_mnist(mnist_db_path);

#ifdef MNIST_LIMIT_TRAIN_DB
	mnist_ntrain_images = mnist_ntrain_images < MNIST_LIMIT_TRAIN_DB ?
		mnist_ntrain_images : MNIST_LIMIT_TRAIN_DB;
#endif /* MNIST_LIMIT_TRAIN_DB */
#ifdef MNIST_LIMIT_TEST_DB
	mnist_ntest_images = mnist_ntest_images < MNIST_LIMIT_TEST_DB ?
		mnist_ntest_images : MNIST_LIMIT_TEST_DB;
#endif /* MNIST_LIMIT_TEST_DB */

	printf("Train DB: %ld images\n", mnist_ntrain_images);
	printf("Test DB: %ld images\n", mnist_ntest_images);


	mlp_train();
	mlp_test();

	mnist_save_datasets();

	mlp_save_weights();

	release_resources();

	return 0;
}

void release_resources()
{
	if(mnist_train_images != NULL)
		free(mnist_train_images);

	if(mnist_train_labels != NULL)
		free(mnist_train_labels);

	if(mnist_test_images != NULL)
		free(mnist_test_images);

	if(mnist_test_labels != NULL)
		free(mnist_test_labels);

	mnist_ntrain_images = 0;
	mnist_train_images = NULL;
	mnist_train_labels = NULL;
	mnist_ntest_images = 0;
	mnist_test_images = NULL;
	mnist_test_labels = NULL;
}

void load_mnist(const char *mnist_path)
{
	char path[4096];
	struct mnist_images *images;
	struct mnist_labels *labels;

	printf("Loading MNIST data ...\n");

	snprintf(path, sizeof(path), "%s/train-images-idx3-ubyte", mnist_path);
	printf("-> %s\n", path);
	images = mnist_load_images(path);
	if(images == NULL)
		goto error;
	mnist_ntrain_images = images->num_images;
	mnist_train_images = mnist_images_convert(images, MNIST_IMAGE_MIN, MNIST_IMAGE_MAX);
	free(images);
	if(mnist_train_images == NULL)
		goto error;

	snprintf(path, sizeof(path), "%s/train-labels-idx1-ubyte", mnist_path);
	printf("-> %s\n", path);
	labels = mnist_load_labels(path);
	if(labels == NULL)
		goto error;
	mnist_train_labels = mnist_labels_convert(labels, MNIST_LABEL_MAX);
	free(labels);
	if(mnist_train_labels == NULL)
		goto error;

	snprintf(path, sizeof(path), "%s/t10k-images-idx3-ubyte", mnist_path);
	printf("-> %s\n", path);
	images = mnist_load_images(path);
	if(images == NULL)
		goto error;
	mnist_ntest_images = images->num_images;
	mnist_test_images = mnist_images_convert(images, MNIST_IMAGE_MIN, MNIST_IMAGE_MAX);
	free(images);
	if(mnist_test_images == NULL)
		goto error;

	snprintf(path, sizeof(path), "%s/t10k-labels-idx1-ubyte", mnist_path);
	printf("-> %s\n", path);
	labels = mnist_load_labels(path);
	if(labels == NULL)
		goto error;
	mnist_test_labels = mnist_labels_convert(labels, MNIST_LABEL_MAX);
	free(labels);
	if(mnist_test_labels == NULL)
		goto error;

	return;

error:
	printf("Failed to load: %s\n", path);
	release_resources();
	exit(-1);
}

void mlp_train()
{
	size_t batch, nbatches = mnist_ntrain_images / MLP_BATCH;
	size_t epoch, nepochs = MLP_EPOCHS;
	size_t epoch1, nepochs1 = MLP_EPOCHS_B;
	size_t image, nimages = MLP_BATCH;

	printf("Training MLP ...\n");
	printf("Momentum factor : %0.8f\n", MLP_MF);
	printf("Learning rate   : %0.8f\n", MLP_LR);
	printf("Weight decay    : %0.8f\n", MLP_WD);
	printf("Batch size      : %d\n", MLP_BATCH);
	printf("Total batches   : %ld\n", mnist_ntrain_images / MLP_BATCH);
	printf("Epochs per batch: %d\n", MLP_EPOCHS_B);
	printf("Epochs          : %d\n", MLP_EPOCHS);
	printf("\n");

	/* Prepare for training */
	enn_mlp_rand_weights(&mlp_trainer);
	enn_mlp_reset_diffs(&mlp_trainer);

	for(epoch = 0; epoch < nepochs; ++epoch) {
		for(batch = 0; batch < nbatches; ++batch) {
			printf("Starting: Epoch = %ld / %ld, Batch %ld / %ld ...\n", epoch + 1, nepochs,
				batch + 1, nbatches);
			for(epoch1 = 0; epoch1 < nepochs1; ++epoch1) {
				for(image = 0; image < nimages; ++image) {
					size_t p = batch * MLP_BATCH + image;
					/* Propagate */
					enn_propagate(&mlp, &mnist_train_images[p].data[0][0]);
					/* Backpropagate */
					enn_mlp_backprop(&mlp_trainer, &mnist_train_images[p].data[0][0],
						&mnist_train_labels[p].data[0]);
				}
			}
			printf("Intermediate result: Epoch = %ld / %ld, Batch %ld / %ld\n", epoch + 1, nepochs,
				batch + 1, nbatches);
			for(image = 0; image < nimages; ++image) {
				size_t p = batch * MLP_BATCH + image;
				/* Propagate */
				enn_propagate(&mlp, &mnist_train_images[p].data[0][0]);
				print_current_result(image, mnist_train_labels);
				printf("\n");
			}
			printf("\n");
		}
	}
	printf("Training completed.\n\n");
}

void mlp_test()
{
	size_t p, n = mnist_ntest_images;
	size_t match;
	size_t total = 0, matches = 0;
	char path[4096];
	FILE *fh;

	snprintf(path, sizeof(path), "%s/test_matches.h", output_path);
	fh = fopen(path, "w");
	if(!fh)
		printf("Failed to open: %s\n", path);
	else
		fprintf(fh, "int test_matches[%zu] = {\n", n);

	printf("Testing MLP ...\n");
	for(p = 0; p < n; ++p) {
		enn_propagate(&mlp, &mnist_test_images[p].data[0][0]);
		match = print_current_result(p, mnist_test_labels);
		if(fh) {
			fprintf(fh, "\t%zu", match);
			if(p < n - 1) fprintf(fh, ",");
			fprintf(fh, "\n");
		}
		matches += match;
		total += 1;
		printf("\n");
	}

	if(fh) {
		fprintf(fh, "};\n");
		fclose(fh);
	}

	printf("Total = %ld, Matches = %ld\n\n", total, matches);
}

void mlp_save_weights()
{
	char path[4096];

	printf("Saving weights ...\n");

	snprintf(path, sizeof(path), "%s/mlp_weights1.h", output_path);
	printf("<- %s\n", path);
	enn_store_layer_weights(&mlp_prod1, path, "mlp_weights_layer1", "float");

	snprintf(path, sizeof(path), "%s/mlp_weights2.h", output_path);
	printf("<- %s\n", path);
	enn_store_layer_weights(&mlp_prod2, path, "mlp_weights_layer2", "float");
}

int best_result_pos(const double *out)
{
	int p = 0;

	for(int i = 1; i < 10; ++i)
		if(out[i] > out[p])
			p = i;
	return p;
}

int print_current_result(size_t sample, struct mnist_double_label *labels)
{
	const double *result;
	size_t i;
	int m = 0;

	result = enn_get_output(&mlp);
	for(i = 0; i < 10; ++i) {
		printf("\t%.2f/%.2f", result[i], labels[sample].data[i]);
		if(best_result_pos(result) == best_result_pos(labels[sample].data))
			m = 1;
	}
	if(m) printf("\tM");
	return m;
}

void enn_store_layer_weights(struct enn_prod_layer *pl, const char *path, const char *name, const char *type)
{
	size_t i;
	size_t n = (pl->ni + 1) * pl->base.no;
	FILE *fh = fopen(path, "w");

	if(fh == NULL) {
		printf("Failed to open: %s\n", path);
		return;
	}

	fprintf(fh, "%s %s[%zu] = {\n", type, name, n);
	for(i = 0; i < n; ++i) {
		fprintf(fh, "\t%.8f", pl->weights[i]);
		if(i < n - 1) fprintf(fh, ",");
		if(i % (pl->ni + 1) == 0) fprintf(fh, "\t/* Bias; Neuron %zu */", i / (pl->ni + 1));
		fprintf(fh, "\n");
	}
	fprintf(fh, "};\n");

	fclose(fh);
}

void mnist_store_images(struct mnist_double_image *images, size_t n, const char *path, const char *name,
			const char *type)
{
	size_t i, j;
	const size_t imsz = sizeof(images[0].data) / sizeof(images[0].data[0][0]);	/* MNIST image size */
	FILE *fh = fopen(path, "w");

	if(fh == NULL) {
		printf("Failed to open: %s\n", path);
		return;
	}

	fprintf(fh, "%s %s[%zu][%zu] = {\n", type, name, n, imsz);
	for(i = 0; i < n; ++i) {
		double *img = &images[i].data[0][0];
		fprintf(fh, "\t{");
		for(j = 0; j < imsz; ++j) {
			fprintf(fh, " %.8f", img[j]);
			if(j < imsz - 1) fprintf(fh, ",");
		}
		fprintf(fh, " }");
		if(i < n - 1) fprintf(fh, ",");
		fprintf(fh, "\n");
	}
	fprintf(fh, "};\n");

	fclose(fh);
}

void mnist_store_labels(struct mnist_double_label *labels, size_t n, const char *path, const char *name,
			const char *type)
{
	size_t i, j;
	const size_t ll = sizeof(labels[0].data) / sizeof(labels[0].data[0]);	/* MNIST label length */
	FILE *fh = fopen(path, "w");

	if(fh == NULL) {
		printf("Failed to open: %s\n", path);
		return;
	}

	fprintf(fh, "%s %s[%zu][%zu] = {\n", type, name, n, ll);
	for(i = 0; i < n; ++i) {
		fprintf(fh, "\t{");
		for(j = 0; j < ll; ++j) {
			fprintf(fh, " %.8f", labels[i].data[j]);
			if(j < ll - 1) fprintf(fh, ",");
		}
		fprintf(fh, " }");
		if(i < n - 1) fprintf(fh, ",");
		fprintf(fh, "\n");
	}
	fprintf(fh, "};\n");

	fclose(fh);
}

void mnist_save_datasets()
{
	char path[4096];

	printf("Saving datasets ...\n");

	snprintf(path, sizeof(path), "%s/mnist_train_images.h", output_path);
	printf("<- %s\n", path);
	mnist_store_images(mnist_train_images, mnist_ntrain_images, path, "mnist_train_images", "float");

	snprintf(path, sizeof(path), "%s/mnist_train_labels.h", output_path);
	printf("<- %s\n", path);
	mnist_store_labels(mnist_train_labels, mnist_ntrain_images, path, "mnist_train_labels", "float");

	snprintf(path, sizeof(path), "%s/mnist_test_images.h", output_path);
	printf("<- %s\n", path);
	mnist_store_images(mnist_test_images, mnist_ntest_images, path, "mnist_test_images", "float");

	snprintf(path, sizeof(path), "%s/mnist_test_labels.h", output_path);
	printf("<- %s\n", path);
	mnist_store_labels(mnist_test_labels, mnist_ntest_images, path, "mnist_test_labels", "float");
}
