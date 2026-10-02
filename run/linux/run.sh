#!/bin/bash
this_dir="$(dirname "$(realpath "$0")")"
cd "$this_dir" || exit 1

if [ "$1" = -u ];then
    make -C rootfses
fi
#qemu-system-i386-patched \
qemu_args=(
    -kernel ./bzImage
    -initrd ./rootfses/initrd.img
    -drive file=./rootfses/arch.qcow2
    -append "console=ttyS0 nokaslr"
    -nographic
    -enable-kvm
    -s  # Shorthand  for  -gdb  <tcp::1234>
    -nic "user,hostfwd=tcp::2222-:22"
    #-S # stop
    #-smp 2
    )

#for arg in "${qemu_args[@]}";do
#    echo "$arg"
#done
qemu-system-x86_64 "${qemu_args[@]}"
