# The VxEngine Project
# User mode driver Makefile

# Build targets
TARGETS :=


# User mode driver build options
LIBVXENGINE_TARGET := libvxengine.so
LIBVXENGINE_CXX_FILES :=	\
	src/entry.cxx
LIBVXENGINE_HXX_FILES :=	\
	include/vxe.hxx
	# must be C-header
LIBVXENGINE_CFLAGS := --std=c++14 -O3 -g -Wall -Iinclude -Icommon
LIBVXENGINE_LDFLAGS := --shared -fPIC


###### System model build options
UDTEST_TARGET := udtest
UDTEST_CXX_FILES :=	\
	test/main.cxx
UDTEST_HXX_FILES :=	\
	include/vxe.hxx
UDTEST_CFLAGS := --std=c++14 -O3 -g -Wall -Iinclude
UDTEST_LDFLAGS := -L. -lvxengine


# Add targets to build
TARGETS += $(LIBVXENGINE_TARGET)
TARGETS += $(UDTEST_TARGET)


# Main goal
.PHONY: all
all: $(TARGETS)
	@echo "Done."


######## Simple test build target
$(LIBVXENGINE_TARGET): $(LIBVXENGINE_CXX_FILES) $(LIBVXENGINE_HXX_FILES)
	@echo "Building [$(LIBVXENGINE_TARGET)]"
	@g++ $(LIBVXENGINE_CFLAGS) -o $(LIBVXENGINE_TARGET)	\
		$(LIBVXENGINE_CXX_FILES) $(LIBVXENGINE_LDFLAGS)

###### System model build target
$(UDTEST_TARGET): $(UDTEST_CXX_FILES) $(UDTEST_HXX_FILES) $(LIBVXENGINE_TARGET)
	@echo "Building [$(UDTEST_TARGET)]"
	@g++ $(UDTEST_CFLAGS) -o $(UDTEST_TARGET)	\
		$(UDTEST_CXX_FILES) $(UDTEST_LDFLAGS)


# Do clean
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
