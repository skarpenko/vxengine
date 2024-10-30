# The VxEngine Project
# Vector processing unit testbench


# Available testbenches
TESTBENCHES := \
	tb_vxe_vpu_cmd_queue		\
	tb_vxe_vpu_lsu			\
	tb_vxe_vpu_thread_rf		\
	tb_vxe_vpu_cmd_dispatch		\
	tb_vxe_vpu_rf			\
	tb_vxe_vpu_regu_ecu		\
	tb_vxe_vpu_actf_ecu		\
	tb_vxe_vpu_actf_eu		\
	tb_vxe_vpu_stor_ecu		\
	tb_vxe_vpu_stor_eu		\
	tb_vxe_vpu_prod_ecu		\
	tb_vxe_vpu_prod_eu_agen		\
	tb_vxe_vpu_prod_eu_rq_disp	\
	tb_vxe_vpu_prod_eu_rs_dist	\
	tb_vxe_vpu_prod_eu_fmac		\
	tb_vxe_vpu_prod_eu


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
