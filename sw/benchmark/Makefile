# The VxEngine Project
# Benchmark application Makefile


# Build targets
TARGETS :=


# Additional compiler and linker arguments
ifdef VXENGINE_HOME
  EXTRA_CFLAGS ?= -I$(VXENGINE_HOME)/sw/ud/include
  EXTRA_LDFLAGS ?= -Wl,-rpath=$(VXENGINE_HOME)/sw/ud -L$(VXENGINE_HOME)/sw/ud
endif


# Benchmark application build options
VXEBM_TARGET := vxebm
VXEBM_CXX_FILES :=	\
	vxebm_main.cxx
VXEBM_CFLAGS := $(EXTRA_CFLAGS) --std=c++11 -O3 -g -Wall
VXEBM_LDFLAGS := $(EXTRA_LDFLAGS) -lvxengine


# Add targets to build
TARGETS += $(VXEBM_TARGET)


# Main goal
.PHONY: all
all: $(TARGETS)
	@echo "Done."


# Benchmark application build target
$(VXEBM_TARGET): $(VXEBM_CXX_FILES)
	@echo "Building [$(VXEBM_TARGET)]"
	@g++ $(VXEBM_CFLAGS) -o $(VXEBM_TARGET) $(VXEBM_CXX_FILES) $(VXEBM_LDFLAGS)


# Do clean
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
