DEB_BUILD_ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)

.PHONY: all powerpc i386 amd64 x86 clean sbm ipxe memtest dos

all: $(DEB_BUILD_ARCH)

powerpc:

i386: x86

amd64: x86

x86: sbm ipxe memtest dos

sbm: build/sbm-stamp

ipxe: build/ipxe-stamp

memtest: build/memtest-stamp

dos: build/dos-stamp

build/sbm-stamp:
	rm -rf build/sbm
	mkdir -p build
	dpkg-source -x sources/sbm/sbm_3.7.1-9.1.dsc build/sbm
	patch -d build/sbm -p0 <build/sbm/debian/patches/3.7.2.patch
	patch -d build/sbm -p1 <build/sbm/debian/patches/amd64.patch
	patch -d build/sbm -p0 <build/sbm/debian/patches/major-minor.patch
	patch -d build/sbm -p0 <build/sbm/debian/patches/sbminst-image.patch
	patch -d build/sbm -p1 <patches/sbm/sbm-3.7.1-nodocs.patch
	make -C build/sbm
	build/sbm/release/sbminst -y -d IMAGE -f build/sbm/sbm.img
	utils/sbm/pad-floppy build/sbm/sbm.img
	install -m 0755 -d binaries
	gzip -9 -c <build/sbm/sbm.img >binaries/sbm.imz
	touch build/sbm-stamp

build/ipxe-stamp:
	rm -rf build/ipxe
	mkdir -p build/ipxe
	tar -ax --strip-components=1 -C build/ipxe -f sources/ipxe/ipxe-git.20140129.3fa7a3b.tar.xz
	make -C build/ipxe/src bin/ipxe.lkrn V=1 EXTRAVERSION="+ (Finnix $(shell dpkg-parsechangelog | grep Version: | cut -d' ' -f2-))"
	install -m 0755 -d binaries
	install -m 0644 build/ipxe/src/bin/ipxe.lkrn binaries/ipxe
	touch build/ipxe-stamp

build/memtest-stamp:
	rm -rf build/memtest
	mkdir -p build/memtest
	tar -ax --strip-components=1 -C build/memtest -f sources/memtest/memtest86+-5.01.tar.gz
	patch -d build/memtest -p1 <patches/memtest/memtest86+-5.01-finnix.patch
	make -C build/memtest memtest.bin
	install -m 0755 -d binaries
	install -m 0644 build/memtest/memtest.bin binaries/memtest
	touch build/memtest-stamp

build/dos-stamp:
	mkdir -p build
	# Nothing to do to actually build
	install -m 0755 -d binaries
	install -m 0644 sources/dos/dos.imz binaries/dos.imz
	touch build/dos-stamp

clean:
	rm -rf build
	rm -rf binaries
