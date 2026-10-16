#!/bin/bash -e

this_dir="$(dirname "$(realpath "$0")")"
cd "$this_dir"

initrd_img=initrd.img
initrd_root="initrd"
patch_udev(){
    local extract_dir=".extract"
    mkdir -p "$extract_dir"

    pkg_dir="../pkgs/udev"

    udev=(udev libc6 libselinux1 libsepol1)
    modprobe=(module-init-tools)
    pkgs=()
    pkgs+=("${udev[@]}")
    pkgs+=("${modprobe[@]}")
    for pkg in "${pkgs[@]}";do
        echo "$pkg"
        ar --output="$extract_dir" x  "$(find "$pkg_dir" -name "${pkg}_*.deb" | tail -n 1)"
        tar -C "$initrd_root" -xzf "$extract_dir"/data.tar.gz
    done
    rm -r "$extract_dir"
}
main(){
    patch_udev
    #(
    #    cd "$initrd_root"
    #    find . |cpio -R 0:0  -o --format=newc  > ../initrd.img
    #)
    { cd "$initrd_root" ; find . ; } |\
            cpio -D "$initrd_root" -R 0:0 -o --format=newc  > "$initrd_img"
    return 0
}
main "$@"

