DOCKER ?= docker.educg.net/cg/os-contest:20250614
NPROC ?= 16
XZ_THREADS ?= $(NPROC)

all: sdcard

build-all: build-rv build-la

build-rv:
	make -f Makefile.sub clean
	mkdir -p sdcard/riscv/musl
	make -f Makefile.sub PREFIX=riscv64-buildroot-linux-musl- DESTDIR=/code/sdcard/riscv/musl NPROC=$(NPROC)
	cp /opt/riscv64--musl--bleeding-edge-2020.08-1/riscv64-buildroot-linux-musl/sysroot/lib/libc.so sdcard/riscv/musl/lib
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-musl ####/g' sdcard/riscv/musl/*_testcode.sh

	make -f Makefile.sub clean
	mkdir -p sdcard/riscv/glibc
	make -f Makefile.sub PREFIX=riscv64-linux-gnu- DESTDIR=/code/sdcard/riscv/glibc NPROC=$(NPROC)
	cp /usr/riscv64-linux-gnu/lib/libc.so.6 sdcard/riscv/glibc/lib/libc.so
	cp /usr/riscv64-linux-gnu/lib/libc.so.6 sdcard/riscv/glibc/lib/
	cp /usr/riscv64-linux-gnu/lib/libm.so.6 sdcard/riscv/glibc/lib/libm.so
	cp /usr/riscv64-linux-gnu/lib/libm.so.6 sdcard/riscv/glibc/lib/
	cp /usr/riscv64-linux-gnu/lib/ld-linux-riscv64-lp64d.so.1 sdcard/riscv/glibc/lib/ld-linux-riscv64-lp64d.so.1
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-glibc ####/g' sdcard/riscv/glibc/*_testcode.sh

build-la:
	make -f Makefile.sub clean
	mkdir -p sdcard/loongarch/musl
	make -f Makefile.sub PREFIX=loongarch64-linux-musl- DESTDIR=/code/sdcard/loongarch/musl NPROC=$(NPROC)
	cp /opt/loongarch64-linux-musl-cross/loongarch64-linux-musl/lib/libc.so sdcard/loongarch/musl/lib
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-musl ####/g' sdcard/loongarch/musl/*_testcode.sh

	make -f Makefile.sub clean
	mkdir -p sdcard/loongarch/glibc
	make -f Makefile.sub PREFIX=loongarch64-linux-gnu- DESTDIR=/code/sdcard/loongarch/glibc NPROC=$(NPROC)
	cp /opt/gcc-13.2.0-loongarch64-linux-gnu/sysroot/usr/lib64/libc.so.6 sdcard/loongarch/glibc/lib
	cp /opt/gcc-13.2.0-loongarch64-linux-gnu/sysroot/usr/lib64/libm.so.6 sdcard/loongarch/glibc/lib
	cp /opt/gcc-13.2.0-loongarch64-linux-gnu/sysroot/usr/lib64/ld-linux-loongarch-lp64d.so.1 sdcard/loongarch/glibc/lib
	sed -E -i 's/#### OS COMP TEST GROUP ([^ ]+) ([^ ]+) ####/#### OS COMP TEST GROUP \1 \2-glibc ####/g' sdcard/loongarch/glibc/*_testcode.sh

sdcard: build-all .PHONY
	rm -rf mnt
	mkdir -p mnt
	cp -rL sdcard/riscv/* mnt
	cp mnt/musl/lib/dlopen_dso.so mnt/musl
	cp mnt/musl/lib/tls_get_new-dtv_dso.so mnt/musl
	cp mnt/glibc/lib/dlopen_dso.so mnt/glibc
	cp mnt/glibc/lib/tls_get_new-dtv_dso.so mnt/glibc
	dd if=/dev/zero of=sdcard-rv.img count=4096 bs=1M
	mkfs.ext4 -d mnt sdcard-rv.img
	rm -rf mnt
	xz -T$(XZ_THREADS) -0 -f sdcard-rv.img

	rm -rf mnt
	mkdir -p mnt
	cp -rL sdcard/loongarch/* mnt
	cp mnt/musl/lib/dlopen_dso.so mnt/musl
	cp mnt/musl/lib/tls_get_new-dtv_dso.so mnt/musl
	cp mnt/glibc/lib/dlopen_dso.so mnt/glibc
	cp mnt/glibc/lib/tls_get_new-dtv_dso.so mnt/glibc
	dd if=/dev/zero of=sdcard-la.img count=4096 bs=1M
	mkfs.ext4 -d mnt sdcard-la.img
	rm -rf mnt
	xz -T$(XZ_THREADS) -0 -f sdcard-la.img


clean:
	make -f Makefile.sub clean
	rm -rf sdcard/riscv/*
	rm -rf sdcard/loongarch/*
	rm -f sdcard-la.img.xz
	rm -f sdcard-rv.img.xz

docker:
	docker run --rm -it -v .:/code --entrypoint bash -w /code --privileged $(DOCKER)


.PHONY:
