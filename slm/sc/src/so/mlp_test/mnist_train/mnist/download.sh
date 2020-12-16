#!/bin/sh
# Download MNIST database

wget http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz
wget http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz
wget http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz
wget http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz

gunzip -k train-images-idx3-ubyte.gz
gunzip -k train-labels-idx1-ubyte.gz
gunzip -k t10k-images-idx3-ubyte.gz
gunzip -k t10k-labels-idx1-ubyte.gz
