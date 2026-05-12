DOCKER ?= docker.educg.net/cg/os-contest:20250614
NPROC ?= 8
RT_TESTS_JOBS ?= 1
XZ_THREADS ?= $(NPROC)
GZIP_THREADS ?= $(NPROC)
PACK_JOBS ?= 2
IMAGE_SIZE ?= 4G
PIGZ := $(shell command -v pigz 2>/dev/null)
ifeq ($(PIGZ),)
    GZIP ?= gzip
    GZIP_FLAGS ?= -1
else
    GZIP ?= pigz
    GZIP_FLAGS ?= -1 -p $(GZIP_THREADS)
endif

all: sdcard

build-all: build-rv build-la

build-rv:
	make -f Makefile.sub clean
	mkdir -p sdcard/riscv/musl
	make -f Makefile.sub PREFIX=riscv64-buildroot-linux-musl- DESTDIR=/code/sdcard/riscv/musl NPROC=$(NPROC) RT_TESTS_JOBS=$(RT_TESTS_JOBS)
	cp /opt/riscv64--musl--bleeding-edge-2020.08-1/riscv64-buildroot-linux-musl/sysroot/lib/libc.so sdcard/riscv/musl/lib
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-musl ####/g' sdcard/riscv/musl/*_testcode.sh

	make -f Makefile.sub clean
	mkdir -p sdcard/riscv/glibc
	make -f Makefile.sub PREFIX=riscv64-linux-gnu- DESTDIR=/code/sdcard/riscv/glibc NPROC=$(NPROC) RT_TESTS_JOBS=$(RT_TESTS_JOBS)
	cp /usr/riscv64-linux-gnu/lib/libc.so.6 sdcard/riscv/glibc/lib/libc.so
	cp /usr/riscv64-linux-gnu/lib/libc.so.6 sdcard/riscv/glibc/lib/
	cp /usr/riscv64-linux-gnu/lib/libm.so.6 sdcard/riscv/glibc/lib/libm.so
	cp /usr/riscv64-linux-gnu/lib/libm.so.6 sdcard/riscv/glibc/lib/
	cp /usr/riscv64-linux-gnu/lib/ld-linux-riscv64-lp64d.so.1 sdcard/riscv/glibc/lib/ld-linux-riscv64-lp64d.so.1
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-glibc ####/g' sdcard/riscv/glibc/*_testcode.sh

build-la:
	make -f Makefile.sub clean
	mkdir -p sdcard/loongarch/musl
	make -f Makefile.sub PREFIX=loongarch64-linux-musl- DESTDIR=/code/sdcard/loongarch/musl NPROC=$(NPROC) RT_TESTS_JOBS=$(RT_TESTS_JOBS)
	cp /opt/loongarch64-linux-musl-cross/loongarch64-linux-musl/lib/libc.so sdcard/loongarch/musl/lib
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-musl ####/g' sdcard/loongarch/musl/*_testcode.sh

	make -f Makefile.sub clean
	mkdir -p sdcard/loongarch/glibc
	make -f Makefile.sub PREFIX=loongarch64-linux-gnu- DESTDIR=/code/sdcard/loongarch/glibc NPROC=$(NPROC) RT_TESTS_JOBS=$(RT_TESTS_JOBS)
	cp /opt/gcc-13.2.0-loongarch64-linux-gnu/sysroot/usr/lib64/libc.so.6 sdcard/loongarch/glibc/lib
	cp /opt/gcc-13.2.0-loongarch64-linux-gnu/sysroot/usr/lib64/libm.so.6 sdcard/loongarch/glibc/lib
	cp /opt/gcc-13.2.0-loongarch64-linux-gnu/sysroot/usr/lib64/ld-linux-loongarch-lp64d.so.1 sdcard/loongarch/glibc/lib
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-glibc ####/g' sdcard/loongarch/glibc/*_testcode.sh

sdcard: build-all
	$(MAKE) pack-sdcard

pack-sdcard:
	$(MAKE) -j $(PACK_JOBS) pack-rv pack-la

pack-rv:
	rm -rf mnt-rv
	mkdir -p mnt-rv
	cp -rL sdcard/riscv/* mnt-rv
	cp mnt-rv/musl/lib/dlopen_dso.so mnt-rv/musl
	cp mnt-rv/musl/lib/tls_get_new-dtv_dso.so mnt-rv/musl
	cp mnt-rv/glibc/lib/dlopen_dso.so mnt-rv/glibc
	cp mnt-rv/glibc/lib/tls_get_new-dtv_dso.so mnt-rv/glibc
	rm -f sdcard-rv.img
	truncate -s $(IMAGE_SIZE) sdcard-rv.img
	mkfs.ext4 -d mnt-rv sdcard-rv.img
	rm -rf mnt-rv
	$(GZIP) $(GZIP_FLAGS) -c sdcard-rv.img > sdcard-rv.img.gz
	xz -T$(XZ_THREADS) -0 -f sdcard-rv.img

pack-la:
	rm -rf mnt-la
	mkdir -p mnt-la
	cp -rL sdcard/loongarch/* mnt-la
	cp mnt-la/musl/lib/dlopen_dso.so mnt-la/musl
	cp mnt-la/musl/lib/tls_get_new-dtv_dso.so mnt-la/musl
	cp mnt-la/glibc/lib/dlopen_dso.so mnt-la/glibc
	cp mnt-la/glibc/lib/tls_get_new-dtv_dso.so mnt-la/glibc
	rm -f sdcard-la.img
	truncate -s $(IMAGE_SIZE) sdcard-la.img
	mkfs.ext4 -d mnt-la sdcard-la.img
	rm -rf mnt-la
	$(GZIP) $(GZIP_FLAGS) -c sdcard-la.img > sdcard-la.img.gz
	xz -T$(XZ_THREADS) -0 -f sdcard-la.img


clean:
	make -f Makefile.sub clean
	rm -rf sdcard/riscv/*
	rm -rf sdcard/loongarch/*
	rm -f sdcard-la.img.xz
	rm -f sdcard-rv.img.xz
	rm -f sdcard-la.img.gz
	rm -f sdcard-rv.img.gz

docker:
	docker run --rm -it -v .:/code --entrypoint bash -w /code --privileged $(DOCKER)


.PHONY: all build-all build-rv build-la sdcard pack-sdcard pack-rv pack-la clean docker
