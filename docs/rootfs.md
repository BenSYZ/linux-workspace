## create
qemu-img convert -f raw -O qcow2 arch.img arch.qcow2.new
or
qemu-img create -f qcow2 arch.qcow2 16G

## mount
sudo modprobe nbd nbds_max=2
sudo qemu-nbd --connect=/dev/nbd0 arch.qcow2
