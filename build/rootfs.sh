#!/bin/bash
# shellcheck disable=2031
build_img=rootfs.img
mount_root="debian-4"
debian_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
main(){
    mkdir -p "$mount_root"
    ln -s ../run/linux/rootfses/debian-4.qcow2 .
    (
        source ../run/linux/rootfses/debian-4.sh
        _connect
        _fsck

        #sudo dd if="$nbd_dev"p2 of=./rootfs.img conv=sparse
        #sudo dd if="$nbd_dev"p2 of=./rootfs.img conv=sparse
        sudo cp "$nbd_dev"p2 "$build_img" --sparse=always
        sudo chown "$UID":"$UID" "$build_img"

        _fsck
        _disconnect
    )
    rm "debian-4.qcow2"

    # let ext2 to support extents so that mount id map works
    ## sudo e2fsck -f rootfs.img
    ## sudo tune2fs -O extents,uninit_bg,dir_index rootfs.img
    ## sudo e2fsck -fp rootfs.img

    sudo mount "$build_img" "$mount_root"
    sudo mount --bind ./pkgs/archives "$mount_root"/var/cache/apt/archives

    sudo arch-chroot "$mount_root" env PATH="$debian_path" apt-get -y update
    # linux
    sudo arch-chroot "$mount_root" env PATH="$debian_path" \
        apt-get -y build-dep linux-image-2.6.24-etchnhalf.1-amd64
    # linux target: menuconfig and tags
    sudo arch-chroot "$mount_root" env PATH="$debian_path" \
        apt-get -y install ncurses-dev ctags

    # grub
    sudo arch-chroot "$mount_root" env PATH="$debian_path" \
        apt-get -y build-dep grub
    sudo arch-chroot "$mount_root" env PATH="$debian_path" \
        apt-get -y install fakeroot

    sudo umount "$mount_root"/var/cache/apt/archives
    sudo umount "$mount_root"

    return 0
}
main "$@"

