# The VxEngine Project
# Control unit testbench


# Available testbenches
TESTBENCHES := \
	tb_vxe_cu_cmd_decoder	\
	tb_vxe_cu_fetch_unit	\
	tb_vxe_cu_dispatch_unit	\
	tb_vxe_cu_vpu_fwd_unit	\
	tb_vxe_cu_intr_flt_unit


TB ?=
TARGETS :=


ifneq ($(TB),)
TARGETS :=$(TB)
else
TARGETS := $(TESTBENCHES)
endif


# Icarus Verilog flags
IVFLAGS := -Wall $(EXTRA_IVFLAGS)


.PHONY: all
all: $(TARGETS)


# Remove build results
.PHONY: clean
clean:
	-rm -f $(TARGETS)


# Remove build results and simulation results
.PHONY: cleanall
cleanall:
	-rm -f $(TARGETS)
	-rm -f $(addsuffix .vcd,$(TARGETS))


# Run simulation
.PHONY: sim
sim: $(TARGETS)
	$(foreach tb,$(TARGETS),./$(tb);)


.PHONY: help
help:
	@echo "The VxEngine Project"
	@echo "===================="
	@echo "Targets:"
	@echo "  help     - print this help;"
	@echo "  sim      - run simulation;"
	@echo "  clean    - remove build results;"
	@echo "  cleanall - remove build and simulation results."
	@echo "Arguments:"
	@echo "  TB=<testbench> - specifies testbench to use (default: all)."
	@echo "Available testbenches:"
	@echo "  $(TESTBENCHES)"


%: flists/%.lst
	iverilog $(IVFLAGS) -s $@ -o $@ -f $<
