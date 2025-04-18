# The VxEngine Project
# VxE Assembler


all: vxeasm vxedisasm


vxeasm: vxeasm.cxx vxe_instr.hxx
	g++ -O3 -std=c++11 vxeasm.cxx -o vxeasm


vxedisasm: vxedisasm.cxx vxe_instr.hxx
	g++ -O3 -std=c++11 vxedisasm.cxx -o vxedisasm


vxe.out: vxeasm vxedisasm example.asm
	./vxeasm -x example.asm
	./vxedisasm -x vxe.out


.PHONY: clean
clean:
	-rm -f vxeasm
	-rm -f vxedisasm
	-rm -f vxe.out
