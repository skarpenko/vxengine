# The VxEngine Project
# Floating point testbench


# Available testbenches
TESTBENCHES := \
	tb_flp_unpack \
	tb_flp_pack \
	tb_flp_imult \
	tb_flp_imult_stage \
	tb_flp_shifts \
	tb_flp_norm \
	tb_flp_round \
	tb_flp_mul_test \
	tb_flp_align \
	tb_flp_alignr \
	tb_flp_iadd \
	tb_flp_add_test \
	tb_flp_mac_test \
	tb_flp32_mac_5stg


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
