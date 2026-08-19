# The VxEngine Project
# Linux kernel driver tests


# Path to driver ioctls header
KDHDR ?= $(VXENGINE_HOME)/sw/kd

# Cross-compiler toolchain name
CROSS_COMPILE ?=


all: kdtest


kdtest: main.c
	$(CROSS_COMPILE)gcc -O2 -Wall -I$(KDHDR) -o kdtest main.c


.PHONY: clean
clean:
	-rm -f kdtest
