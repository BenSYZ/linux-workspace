#!/bin/bash -e
nbd_dev=/dev/nbd0
arch_qcow2=arch.qcow2
mount_root=arch

function_prefix="arch_qemu_"
connected(){
    if ! pgrep -f "qemu-nbd --connect=$nbd_dev $arch_qcow2" &>/dev/null;then
        return 1
    fi
    return 0
}
_connect(){
    #local nbd_size
    #nbd_size="$(lsblk -o KNAME,SIZE |awk -v NBD_DEV="$(basename "$NBD_DEV")" '{if ($1==NBD_DEV){print $2}}')"
    #if [[ "$nbd_size" == "0B" ]];then
    #    __connect "$NBD_DEV" "$arch_qcow2"
    #fi
    if ! connected;then
        sudo qemu-nbd --connect="$nbd_dev" "$arch_qcow2"
    fi
}
_disconnect(){
    if connected;then
        sudo qemu-nbd --disconnect "$nbd_dev"
    fi
}

_mounted(){
    local partition="$1"
    local mount_point="$2"
    local test_partition
    test_partition="$(/usr/bin/df --output=source "$mount_point" | tail -n+2)"
    if [[ "$test_partition" != "$partition" ]];then
        return 1
    fi
    return 0
}

_mount(){
    local partition="$nbd_dev"p2
    local mount_point="$mount_root"
    if ! _mounted "$partition" "$mount_point";then
        sudo mount "$partition" "$mount_point"
    fi

    local partition="$nbd_dev"p1
    local mount_point="$mount_root"/boot
    if ! _mounted "$partition" "$mount_point";then
        sudo mount "$partition" "$mount_point"
    fi
}
_umount(){
    local partition="$nbd_dev"p1
    local mount_point="$mount_root"/boot
    if _mounted "$partition" "$mount_point";then
        sudo umount "$partition"
    fi
    local partition="$nbd_dev"p2
    local mount_point="$mount_root"
    if _mounted "$partition" "$mount_point";then
        sudo umount "$partition"
    fi
}


_fsck(){
    { sudo fsck.fat -a "$nbd_dev"p1 || sudo fsck.fat -a "$nbd_dev"p1 ; }
    sudo fsck.ext4 "$nbd_dev"p2
}
arch_qemu_mount(){
    _connect
    _fsck
    _mount
}
arch_qemu_fsck(){
    _connect
    _umount
    _fsck
    _disconnect
}
arch_qemu_umount(){
    _umount
    _fsck
    _disconnect
}

arch_qemu_init(){
    partion_table(){
        cat << EOF
label: gpt
label-id: 16F3BE78-02B0-4909-9601-9EAFC64A0308
device: /dev/sda
unit: sectors
first-lba: 2048
last-lba: 134217694
sector-size: 512

/dev/sda1 : start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=13C0C4AC-9601-4486-8632-D8A8F431D34F
/dev/sda2 : start=     2099200, size=   132116480, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=F77D231A-316C-4C46-91A8-12965C534400
EOF
    }
    qemu-img create -f qcow2 "$arch_qcow2" 64G
    _connect
    # shellcheck disable=2024
    sudo sfdisk "$nbd_dev" < <(partion_table)
    sudo mkfs.fat -F 32 "$nbd_dev"p1
    sudo mkfs.ext4 "$nbd_dev"p2

    sudo mount "$nbd_dev"p2 "$mount_root"
    sudo mkdir -p "$mount_root"/boot
    sudo mount "$nbd_dev"p1 "$mount_root"/boot

    sudo pacstrap -K "$mount_root" base openssh
    _umount
    _disconnect
}

check_env(){
    if ! [ -d "$mount_root" ];then
        mkdir -p "$mount_root"
    fi
    if ! [ -e "$nbd_dev" ];then
        sudo modprobe nbd nbds_max=2
    fi

    if ! [ -e "$arch_qcow2" ];then
        arch_qemu_init
    fi
}

get_avail_args(){
    arg_lists=()
    while read -r arg;do
        arg_lists+=("$arg")
    done < <(sed -n "s/^$function_prefix\(.*\)(){/\1/p" "$0")
    # return ${arg_lists[@]}
}

# https://stackoverflow.com/a/15394738/13033234
check_args(){
    local arg_for_check="$1"
    if [[ " ${arg_lists[*]} " =~ [[:space:]]${arg_for_check}[[:space:]] ]]; then
        return 0
    fi
    return 1
}

show_help(){
    if [ "${#arg_lists[@]}" -eq 0 ];then
        get_avail_args
    fi
    arg_list_str="$(echo "${arg_lists[*]}" | tr " " "|")"
    cat << EOF
Usage:
    $0 <$arg_list_str>
    source $0
EOF
}


main(){
    # zsh: main
    # bash: bash
    if [ "$(basename "$0")" != "arch.sh" ];then
        return
    fi

    get_avail_args
    if [ "$#" -eq 0 ] || [ "$1" = help ];then
        show_help
        return 0
    fi

    if ! check_args "$1";then
        show_help
        return 1
    fi

    func="$function_prefix$1"

    check_env
    eval "$func"
    lsblk
    return 0
}
main "$@"

