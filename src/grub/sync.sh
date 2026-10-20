#!/bin/bash
main(){
    mount_root="../../build/debian-4"
    debian_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    sudo mkdir -p "$mount_root"/"$PWD"/
    sudo mount --bind "$PWD"/.. "$mount_root"/"$PWD"/..
    sudo arch-chroot "$mount_root" env PATH="$debian_path" /bin/bash -c "cd \"$PWD\" && exec ./inner_sync.sh"
    sudo umount "$mount_root"/"$PWD"/..
    sudo chown -R "$USER:$USER" grub
    return 0
}
main "$@"

