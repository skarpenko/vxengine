# The VxEngine Project
# Makefile for U-Boot script

all: u-boot.scr


u-boot.scr: boot.script
	mkimage -T script -d boot.script u-boot.scr


.PHONY: clean
clean:
	-rm -f u-boot.scr
