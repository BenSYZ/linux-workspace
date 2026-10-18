#!/bin/bash -e
nbd_dev=/dev/nbd0
qcow2=arch.qcow2
mount_root=arch
init_pkgs=(base openssh)
# password
# hostname
# ssh_pubkey_file
# proxy
init_config=arch.init.config

function_prefix="self_qemu_"
connected(){
    if ! pgrep -f "qemu-nbd --connect=$nbd_dev $qcow2" &>/dev/null;then
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
        sudo qemu-nbd --connect="$nbd_dev" "$qcow2"
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
    test_partition="$(/usr/bin/df --output=source "$mount_point" 2>/dev/null | tail -n+2)"
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
self_qemu_mount(){
    _connect
    _fsck
    _mount
}
self_qemu_fsck(){
    _connect
    _umount
    _fsck
    _disconnect
}
self_qemu_umount(){
    _umount
    _fsck
    _disconnect
}

self_qemu_init(){
    partition_table(){
        # dumped with sfdisk -d /dev/sda with remove uuid
        cat << EOF
label: gpt
device: /dev/sda
unit: sectors
first-lba: 2048
last-lba: 134217694
sector-size: 512

/dev/sda1 : start=        2048, size=     2097152, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
/dev/sda2 : start=     2099200, size=   132116480, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
    }

    systemd_networkd_config(){
       cat << EOF
[Match]
Name=en*
[Network]
DHCP=yes
EOF
}

    qemu-img create -f qcow2 "$qcow2" 64G
    _connect
    # shellcheck disable=2024
    sudo sfdisk "$nbd_dev" < <(partition_table)
    sudo mkfs.fat -F 32 "$nbd_dev"p1
    sudo mkfs.ext4 "$nbd_dev"p2

    sudo mount "$nbd_dev"p2 "$mount_root"
    sudo mkdir -p "$mount_root"/boot
    sudo mount "$nbd_dev"p1 "$mount_root"/boot

    sudo pacstrap -K "$mount_root" "${init_pkgs[@]}"

    password=1
    hostname=qemu-arch-"$(openssl rand -hex 4)"
    ssh_pubkey_file=~/.ssh/keys/ssh.pub
    proxy=http://10.0.2.2:20172
    if [ -e "$init_config" ];then
        # shellcheck disable=1090
        source "$init_config"
    fi

    echo "root:$password"   | sudo arch-chroot "$mount_root" chpasswd

    echo "$hostname"        | sudo arch-chroot "$mount_root" tee /etc/hostname >/dev/null
    systemd_networkd_config | sudo arch-chroot "$mount_root" tee /etc/systemd/network/en.network >/dev/null

    sudo arch-chroot "$mount_root" cp /etc/skel/.bash* /root

    sudo mkdir "$mount_root"/pkgs
    sudo mount --bind -o ro ../pkgs/ "$mount_root"/pkgs

    pkg_file(){
        echo -n "/pkgs/"
        find ../pkgs/"$1"* -exec basename {} \; |grep -vE 'sig$' | tail -n1
    }
    sudo arch-chroot "$mount_root" pacman -S --noconfirm python
    sudo arch-chroot "$mount_root" pacman -U --noconfirm \
        "$(pkg_file archlinuxcn-keyring)"
    sudo arch-chroot "$mount_root" pacman -U --noconfirm \
        "$(pkg_file systemd-rc-local)" \
        "$(pkg_file pacman-archive)"

    # shellcheck disable=2024
    echo '#!/bin/bash' | sudo arch-chroot "$mount_root" tee "/etc/rc.local" >/dev/null
    sudo arch-chroot "$mount_root" chmod +x "/etc/rc.local"
    sudo arch-chroot "$mount_root" systemctl enable rc-local.service

    sudo arch-chroot "$mount_root" mv /var/lib/pacman-archive/pacman.conf /etc/pacman.conf


    sudo pkill -f -- "gpg-agent --homedir $(realpath $mount_root)"'/*etc/pacman.d/gnupg'

    sudo umount "$mount_root"/pkgs
    sudo rmdir "$mount_root"/pkgs

    # TODO: fstab

    sudo arch-chroot "$mount_root" sed -i 's/^#\(DisableSandboxFilesystem\)/\1/' /etc/pacman.conf

    echo "PermitRootLogin prohibit-password" | sudo arch-chroot "$mount_root" tee /etc/ssh/sshd_config.d/90-enable-root.conf >/dev/null
    { cat "$ssh_pubkey_file" || echo -n ; }  | sudo arch-chroot "$mount_root" bash -c "mkdir -p /root/.ssh && tee -a /root/.ssh/authorized_keys" >/dev/null
    cat << EOF | sudo arch-chroot "$mount_root" tee /root/linkup.sh >/dev/null
#!/bin/bash
iface="\$(ip a |awk -v FS=': ' '{if (\$1=="2"){print \$2}}')"
ip link set "\$iface" up
ip address add 10.0.2.15/24 dev "\$iface"
ip route add default via 10.0.2.2
EOF
    sudo arch-chroot "$mount_root" chmod +x /root/linkup.sh >/dev/null

    cat << EOF | sudo arch-chroot "$mount_root" tee /root/sshd.sh >/dev/null
#!/bin/bash
systemctl start sshd
EOF
    sudo arch-chroot "$mount_root" chmod +x /root/sshd.sh >/dev/null

    cat << EOF | sudo arch-chroot "$mount_root" tee -a /root/.bash_profile >/dev/null
export http{,s}_proxy=$proxy
EOF
    sudo umount -R "$mount_root"


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
    local func="$1"
    if ! [ -e "$qcow2" ];then
        if [ "$func" != "self_qemu_init" ];then
            self_qemu_init
        fi
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
self_qemu_nspawn(){
    _connect
    _fsck
    _mount
    sudo systemd-nspawn -b -D "$mount_root" || true
    _umount
    _fsck
    _disconnect
}

self_qemu_chroot(){
    _connect
    _fsck
    _mount
    sudo arch-chroot "$mount_root" || true
    _umount
    _fsck
    _disconnect
}

# update_bootloader
self_qemu_ubl(){
    _connect
    _fsck
    _mount

    sudo install -vT ../bzImage   "$mount_root"/boot/vmlinuz-linux
    sudo install -vT ./initrd.img "$mount_root"/boot/initramfs-linux.img

    if [ -e "$mount_root"/boot/grub/grub.cfg ]; then
        echo "Copy bzImage and initrd, without reconfig"
    else
        sudo arch-chroot "$mount_root" pacman -S --noconfirm --needed efibootmgr grub

        # with --removable grub-install will install as default bootx.efi
        # or we need to do grub-install with kernel-boot up
        sudo arch-chroot "$mount_root" grub-install --target=x86_64-efi --efi-directory=/boot --recheck --removable

        sudo arch-chroot "$mount_root" \
            sed -i 's/^\(#GRUB_TERMINAL_OUTPUT.*\)/\1\nGRUB_TERMINAL_OUTPUT="gfxterm console"/;
                s/^\(GRUB_CMDLINE_LINUX_DEFAULT.*\)/#\1\nGRUB_CMDLINE_LINUX="nokconsole=tty1 console=ttyS0 nokaslr"/' \
                /etc/default/grub

        sudo arch-chroot "$mount_root" chmod -x /etc/grub.d/31_efi_bootnext
        sudo arch-chroot "$mount_root" grub-mkconfig -o /boot/grub/grub.cfg
    fi


    _umount
    _fsck
    _disconnect
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
    check_env "$func"
    eval "$func"
    lsblk
    return 0
}
main "$@"

