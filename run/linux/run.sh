#!/bin/bash
this_dir="$(dirname "$(realpath "$0")")"
cd "$this_dir" || exit 1

# disabled for stop-fsck-start the fsck need sudo
#make -C rootfses

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
kernel_parameters=(
    nokaslr
    #root=/dev/sda2
    root=/dev/hda2
    #console=ttyS0
    #console=tty1
    #init=/bin/bash
    #rdinit=/bin/bash
    )


# shellcheck disable=2054
qemu_args_kernel=(
    -kernel ./bzImage
    -initrd ./rootfses/initrd.img

    #-kernel /mnt/isolinux/vmlinuz
    #-initrd /mnt/isolinux/initrd.img
    #-kernel /tmp/ben/tmp.1791956659_whh/bzImage
    #-initrd /tmp/ben/tmp.1791956659_whh/rootfs.img.2
    #-append "${kernel_parameters[*]}"
    )

# shellcheck disable=2054
qemu_args_bios=(
    --drive media=cdrom,file=../arch/Archlinux-x86_64-2008.03-1-archboot.core.iso,readonly
    -boot once=d
    )

# shellcheck disable=2054
qemu_args_efi=(
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd
    -drive if=pflash,format=raw,readonly=off,file=./firmwares/efi/OVMF_VARS.4m.fd
    )

# shellcheck disable=2054
qemu_args=(
    -enable-kvm
    -m 2G
    -device virtio-vga
    #-nographic
    #-S # stop
    #-smp 2


    -drive file=./rootfses/debian-4.qcow2
    #-drive file=/home/ben/work/grub/grub-0.97/run/disk.img
    # > -blockdev driver=file,node-name=disk_file,filename=./rootfses/debian-4.qcow2
    # > -blockdev driver=qcow2,node-name=disk,file=disk_file

    # > # pcie -> ata
    # > -device driver=ich9-ahci,id=ata_card,addr=04.0
    # > # ata backend
    # > -device driver=ide-hd,drive=disk,bus=ata_card.0
    # > ##-device driver=ide-hd,drive=disk,bus=ide.0

    # > # pcie -> virtio
    # > #-device driver=virtio-blk-pci,id=virtio_card,drive=disk

    -fsdev local,id=fsdev0,path=/tmp/ben,security_model=mapped
    -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare,id=virtio_card1


    "${connections[@]}"
    )

is_graphic(){
    for arg in "$@";do
        if [[ "$arg" =~ -+"nographic" ]];then
            return 1
        fi
    done
    return 0
}

main(){
    # /dev/console=last console=
    if is_graphic "$@";then
        kernel_parameters+=("console=ttyS0")
        kernel_parameters+=("console=tty1")
    else
        kernel_parameters+=("console=tty1")
        kernel_parameters+=("console=ttyS0")
    fi

    qemu_args_kernel+=(-append "${kernel_parameters[*]}")
    qemu_args+=("${qemu_args_kernel[@]}")
    #qemu_args+=("${qemu_args_efi[@]}")
    #qemu_args+=("${qemu_args_bios[@]}")
    qemu_args+=("$@")

    for arg in "${qemu_args[@]}";do
        echo "$arg"
    done
    exec qemu-system-x86_64 "${qemu_args[@]}"

    return 0
}
main "$@"

