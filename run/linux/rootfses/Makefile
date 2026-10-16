.PHONY: initrd debian-4 bootloader
all: initrd debian-4

initrd: initrd.img
initrd.img: $(shell find initrd/ -type f) initrd/usr/bin/busybox  initrd/init initrd.sh
	./initrd.sh
initrd/usr/bin/busybox:
	./initrd.sh

debian-4: .debian-4.fsck
.debian-4.fsck: debian-4.qcow2
	./debian-4.sh fsck
	touch .debian-4.fsck
debian-4.qcow2: initrd/usr/bin/busybox
	./debian-4.sh init

bootloader: initrd debian-4
	./debian-4.sh update_bootloader
