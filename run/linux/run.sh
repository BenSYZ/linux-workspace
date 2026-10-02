#!/bin/bash
this_dir="$(dirname "$(realpath "$0")")"
cd "$this_dir" || exit 1

make -C rootfses

# shellcheck disable=2054
connections=(
    # gdb
    #-s # -gdb tcp::1234
    -chardev socket,path="$(realpath ../.gdb.sock)",server=on,wait=off,id=gdb_core
    -gdb chardev:gdb_core

    # ssh
    #-nic "user,hostfwd=tcp::${PORT_SSH:-2222}-:22"
    -nic "user,hostfwd=unix:$(realpath ../.ssh.sock)-:22"
    #====================
    # Host qemu-arch
    #     ProxyCommand sh -c "nc -U \\\$(pwd)/.ssh.sock"
    #     User root
    #     Hostname localhost
    #     StrictHostKeyChecking no
    #     UserKnownHostsFile /dev/null
    #====================
)




# shellcheck disable=2054
qemu_args=(
    -kernel ./bzImage
    -initrd ./rootfses/initrd.img
    -drive file=./rootfses/arch.qcow2
    -append "console=ttyS0 nokaslr"
    -nographic
    -enable-kvm
    "${connections[@]}"
    #-nic "user,hostfwd=tcp::${PORT_SSH:-2222}-:22"
    #-S # stop
    #-smp 2
    )

#for arg in "${qemu_args[@]}";do
#    echo "$arg"
#done
qemu-system-x86_64 "${qemu_args[@]}"
