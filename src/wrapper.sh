#!/bin/bash
main(){
    this_dir="$(dirname "$(realpath "$0")")"
    mount_root="${this_dir}/../build/debian-4"
    if ! [ -e "$mount_root"/bin ];then
        echo mount "$mount_root" first
        exit 1
    fi
    debian_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    src_dir="$this_dir"
    if ! [ -e "$mount_root$src_dir" ];then
        sudo mkdir -p "$mount_root$src_dir"
        sudo chown "$UID":"$UID" "$mount_root$src_dir"
    fi

    cc_helper_dir=$(realpath "$this_dir"/../build/compile_commands_helper)
    if ! [ -e "$mount_root$cc_helper_dir" ];then
        sudo mkdir -p "$mount_root$cc_helper_dir"
        sudo chown "$UID":"$UID" "$mount_root$cc_helper_dir"
    fi

    bwrap \
        --setenv PATH "$debian_path"             \
        --setenv TERM "xterm"                    \
        --setenv LANG "C"                    \
        --bind "$mount_root" /                   \
        --bind /tmp /tmp                         \
        --dev /dev                               \
        --bind "$src_dir" "$src_dir"             \
        --bind "$cc_helper_dir" "$cc_helper_dir" \
        --uid 0                                  \
        --gid 0                                  \
        --chdir "$PWD"                           \
        "${@:-/bin/bash}"
        #--bind "$PWD" "$PWD" \

    return 0
}
main "$@"

