.PHONY: initrd arch
all: initrd arch

initrd: initrd.img
initrd.img: $(shell find initrd/ -type f) initrd/usr/bin/busybox  initrd/init
	./initrd.sh
initrd/usr/bin/busybox:
	./initrd.sh

arch: .arch.fsck
.arch.fsck: arch.qcow2
	./arch.sh fsck
	touch .arch.fsck
arch.qcow2:
	./arch.sh init
