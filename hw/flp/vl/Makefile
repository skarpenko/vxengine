# The VxEngine Project
# Floating point testbench for Verilator


# Available testbenches
TESTBENCHES := \
	vl_flp_mul_test	\
	vl_flp_add_test


TB ?=
TARGETS :=


ifneq ($(TB),)
TARGETS := $(TB)
else
TARGETS := $(TESTBENCHES)
endif


# Verilator flags
VL_FLAGS   := -CFLAGS -O3 -Wno-fatal -O3 --exe

# Enable trace support
ifneq (,$(filter $(TRACE),1 y yes))
VL_FLAGS += --trace
endif


.PHONY: all
all: $(TARGETS)


# Remove build results
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
	-@rm -fR obj_dir


# Remove build results and simulation results
.PHONY: cleanall
cleanall:
	@echo "Clean all"
	-@rm -f $(TARGETS)
	-@rm -fR obj_dir
	-@rm -f *.vcd


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
	@echo "  TRACE=1        - enable tracing support;"
	@echo "  TB=<testbench> - specifies testbench to use (default: all)."
	@echo "Available testbenches:"
	@echo "  $(TESTBENCHES)"


%: flists/%.lst
	@verilator $(VL_FLAGS) -o ../$@ -f $<
	@$(MAKE) -C obj_dir -f V$@.mk
