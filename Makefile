DEB_BUILD_ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)
export DEB_BUILD_ARCH

KERNEL_JOBS=1
ifneq (,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
KERNEL_JOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
endif
export KERNEL_JOBS

export CURDIR

all: build/kernel-stamp

build/kernel-stamp:
	$(CURDIR)/build_kernels build
	touch build/kernel-stamp

install: build/kernel-stamp
	export DESTDIR
	$(CURDIR)/build_kernels install

clean:
	$(RM) -rf $(CURDIR)/build
