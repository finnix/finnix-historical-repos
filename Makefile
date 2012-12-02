DEB_BUILD_ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)

all: $(DEB_BUILD_ARCH)

powerpc:

i386: x86

amd64: x86

x86: sbm ipxe memtest dos

sbm:
	rm -rf build/sbm
	mkdir -p build
	dpkg-source -x sources/sbm/sbm_3.7.1-9.1.dsc build/sbm
	patch -d build/sbm -p0 <build/sbm/debian/patches/3.7.2.patch
	patch -d build/sbm -p1 <build/sbm/debian/patches/amd64.patch
	patch -d build/sbm -p0 <build/sbm/debian/patches/major-minor.patch
	patch -d build/sbm -p0 <build/sbm/debian/patches/sbminst-image.patch
	patch -d build/sbm -p1 <sources/sbm/nodocs.patch
	make -C build/sbm
	build/sbm/release/sbminst -y -d IMAGE -f build/sbm/sbm.img
	sources/sbm/pad-floppy build/sbm/sbm.img
	install -m 0755 -d binaries
	gzip -9 -c <build/sbm/sbm.img >binaries/sbm.imz

ipxe:
	rm -rf build/ipxe
	mkdir -p build/ipxe
	tar -ax --strip-components=1 -C build/ipxe -f sources/ipxe/ipxe-git.20121120.717279a.tar.xz
	make -C build/ipxe/src bin/ipxe.lkrn
	install -m 0755 -d binaries
	install -m 0644 build/ipxe/src/bin/ipxe.lkrn binaries/ipxe

memtest:
	rm -rf build/memtest
	mkdir -p build/memtest
	tar -ax --strip-components=1 -C build/memtest -f sources/memtest/memtest86+-4.20.tar.gz
	make -C build/memtest memtest.bin
	install -m 0755 -d binaries
	install -m 0644 build/memtest/memtest.bin binaries/memtest

dos:
	install -m 0755 -d binaries
	install -m 0644 sources/dos/dos.imz binaries/dos.imz

clean:
	rm -rf build
	rm -rf binaries
