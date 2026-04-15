# The VxEngine Project
# Quartus compilation flow


# Targets
all: vxengine.sof
rbf: vxengine.rbf


# Main target
vxengine.sof: synth/output_files/vxengine.sof
	cp synth/output_files/vxengine.sof .


# Optional target
vxengine.rbf: config/vxengine.cof vxengine.sof
	quartus_cpf -c config/vxengine.cof


# Compile flow
synth/output_files/vxengine.sof: synth/vxengine.qpf
	quartus_sh --flow compile synth/vxengine


# Create Quartus project
synth/vxengine.qpf: config/creat_proj.tcl
	mkdir synth
	quartus_sh -t config/creat_proj.tcl


# Program FPGA target
.PHONY: prog
prog: config/vxengine.cdf vxengine.sof
	quartus_pgm config/vxengine.cdf


# Clean
.PHONY: clean
clean:
	-rm -Rf synth/


# Clean all
.PHONY: cleanall
cleanall:
	-rm -Rf synth/
	-rm -f vxengine.sof
	-rm -f vxengine.rbf
