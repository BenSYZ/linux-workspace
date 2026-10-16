#!/bin/bash -e

initrd_img=initrd.img
initrd_root="initrd"
extract_busybox(){
    local extract_dir=".busybox_extract"
    mkdir -p "$extract_dir"
    tar --zstd -xf "$(find ../pkgs/ -name "busybox-*.pkg.tar.zst" | tail -n 1)" -C "$extract_dir"
    install -D --target-directory "$initrd_root"/usr/bin/ "$extract_dir"/usr/bin/busybox
    rm -r "$extract_dir"
}
main(){
    if ! [ -e "$initrd_root"/usr/bin/busybox ];then
        extract_busybox
    fi
    if ! [ -e "$initrd_root"/usr/bin/sh ];then
        ln -s busybox "$initrd_root"/usr/bin/sh
    fi
    #(
    #    cd "$initrd_root"
    #    find . |cpio -R 0:0  -o --format=newc  > ../initrd.img
    #)
    { cd "$initrd_root" ; find . ; } |\
            cpio -D "$initrd_root" -R 0:0 -o --format=newc  > "$initrd_img"
    return 0
}
main "$@"

