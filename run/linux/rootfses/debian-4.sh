#!/bin/bash -e

nbd_dev=/dev/nbd0
qcow2=debian-4.qcow2
mount_root=debian-4

init_pkgs=(openssh-server)
# password
# hostname
# ssh_pubkey_file
# proxy
init_config=debian.init.config

function_prefix="self_qemu_"
debian_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
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

    #local partition="$nbd_dev"p1
    #local mount_point="$mount_root"/boot
    #if ! _mounted "$partition" "$mount_point";then
    #    sudo mount "$partition" "$mount_point"
    #fi
}
_umount(){
    #local partition="$nbd_dev"p1
    #local mount_point="$mount_root"/boot
    #if _mounted "$partition" "$mount_point";then
    #    sudo umount "$partition"
    #fi
    local partition="$nbd_dev"p2
    local mount_point="$mount_root"
    if _mounted "$partition" "$mount_point";then
        sudo umount "$partition"
    fi
}


_fsck(){
    #{ sudo fsck.fat -a "$nbd_dev"p1 || sudo fsck.fat -a "$nbd_dev"p1 ; }
    sudo fsck.ext3 "$nbd_dev"p2
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
        # must be dos or grub cannot recognize it
        cat << EOF
label: dos
device: /dev/sda
unit: sectors
sector-size: 512

# reserve 1G
/dev/sda2 : start=     2099200, size=   132118528, type=83
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
    if [ -e initrd/usr/bin/busybox ];then
        ./initrd.sh
    fi

    qemu-img create -f qcow2 "$qcow2" 64G
    _connect
    # shellcheck disable=2024
    sudo sfdisk "$nbd_dev" < <(partition_table)
    # 没驱动：
    # mount: Mounting /dev/hda1 on /root failed: No such file or directory
    # Inode 大小不对
    # mount: Mounting /dev/hda1 on /root failed: Invalid argument
    sudo mkfs.ext3 -I 128 "$nbd_dev"p2

    sudo mount "$nbd_dev"p2 "$mount_root"

    mkdir -p ../pkgs/archives
    sudo debootstrap --cache-dir="$(realpath ../pkgs/archives)" \
                     --no-check-sig --arch=amd64 etch "$mount_root" http://archive.debian.org/debian
    sudo chroot "$mount_root" /bin/mkdir -p /run

    sudo arch-chroot "$mount_root" env PATH="$debian_path" find /var/cache/apt/ -xdev -name '*.deb' -exec rm {} +
    sudo mount --bind ../pkgs/archives "$mount_root"/var/cache/apt/archives # umount at umount -R

    #sudo cp helper/merge_usr "$mount_root"
    #sudo cp initrd/usr/bin/busybox "$mount_root"
    #sudo arch-chroot "$mount_root" /merge_usr
    #sudo rm "$mount_root"/merge_usr "$mount_root"/busybox 

    sudo arch-chroot "$mount_root" env PATH="$debian_path" apt-get -y update
    sudo arch-chroot "$mount_root" env PATH="$debian_path" apt-get -y install "${init_pkgs[@]}"

    password=1
    hostname=qemu-debian-4-"$(openssl rand -hex 4)"
    ssh_pubkey_file=~/.ssh/keys/ssh.pub
    proxy=http://10.0.2.2:20172
    if [ -e "$init_config" ];then
        # shellcheck disable=1090
        source "$init_config"
    fi

    echo "root:$password"   | sudo arch-chroot "$mount_root" env PATH="$debian_path" chpasswd
    echo "$hostname"        | sudo arch-chroot "$mount_root" env PATH="$debian_path" tee /etc/hostname >/dev/null
    #systemd_networkd_config | sudo arch-chroot "$mount_root" tee /etc/systemd/network/en.network >/dev/null

    sudo arch-chroot "$mount_root" env PATH="$debian_path" cp /etc/skel/.bash* /root


    #deb [trusted=yes] http://archive.debian.org/debian etch main contrib non-free
    #deb-src [trusted=yes] http://archive.debian.org/debian etch main contrib non-free
    sudo arch-chroot "$mount_root" env PATH="$debian_path" sed -i \
        's/^deb http/deb [trusted=yes] http/;
         s/main$/main contrib non-free/;
         s/^\(deb\)\( .*\)/\1\2\n\1-src\2/' /etc/apt/sources.list

    #apt-get update
    #apt-get build-dep linux-image-2.6.24-etchnhalf.1-amd64
    #useradd -m -G sudo ben -p 1 -u 1000
    #apt-get install linux-image-2.6.24-etchnhalf.1-amd64 grub
    #export TERM=xterm
    #export LANG=C

    #  update-initramfs  -u


    # enaby tty @ ttyS0
    sudo arch-chroot "$mount_root" env PATH="$debian_path" sed -i \
        's/^#\(.*ttyS0.*\)/\1/' /etc/inittab


    # TODO: fstab

    #echo "PermitRootLogin prohibit-password" | sudo arch-chroot "$mount_root" tee /etc/ssh/sshd_config.d/90-enable-root.conf >/dev/null
    echo "UseDNS no" | sudo arch-chroot "$mount_root" tee -a /etc/ssh/sshd_config >/dev/null
    { cat "$ssh_pubkey_file" || echo -n ; }  | sudo arch-chroot "$mount_root" env PATH="$debian_path" \
        bash -c "mkdir -p /root/.ssh && tee -a /root/.ssh/authorized_keys" >/dev/null
    cat << EOF | sudo arch-chroot "$mount_root" env PATH="$debian_path" tee /root/linkup.sh >/dev/null
#!/bin/bash
iface="\$(ip a |awk -v FS=': ' '{if (\$1=="2"){print \$2}}')"
ip link set "\$iface" up
ip address add 10.0.2.15/24 dev "\$iface"
ip route add default via 10.0.2.2
EOF
    sudo arch-chroot "$mount_root" env PATH="$debian_path" chmod +x /root/linkup.sh >/dev/null

    cat << EOF | sudo arch-chroot "$mount_root" env PATH="$debian_path" tee /root/sshd.sh >/dev/null
#!/bin/bash
systemctl start sshd
EOF
    sudo arch-chroot "$mount_root" env PATH="$debian_path" chmod +x /root/sshd.sh >/dev/null

    cat << EOF | sudo arch-chroot "$mount_root" env PATH="$debian_path" tee -a /root/.bash_profile >/dev/null
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
    sudo arch-chroot "$mount_root" env PATH="$debian_path" bash || true
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
        sudo mount --bind ../pkgs/archives "$mount_root"/var/cache/apt/archives
        sudo arch-chroot "$mount_root" env PATH="$debian_path" apt-get -y update
        sudo arch-chroot "$mount_root" env PATH="$debian_path" apt-get -y install grub
        sudo umount "$mount_root"/var/cache/apt/archives

        # with --removable grub-install will install as default bootx.efi
        # or we need to do grub-install with kernel-boot up
        #sudo arch-chroot "$mount_root" env PATH="$debian_path" grub-install --target=x86_64-efi --efi-directory=/boot --recheck --removable

        #sudo arch-chroot "$mount_root" env PATH="$debian_path" \
        #    sed -i 's/^\(#GRUB_TERMINAL_OUTPUT.*\)/\1\nGRUB_TERMINAL_OUTPUT="gfxterm console"/;
        #        s/^\(GRUB_CMDLINE_LINUX_DEFAULT.*\)/#\1\nGRUB_CMDLINE_LINUX="nokconsole=tty1 console=ttyS0 nokaslr"/' \
        #        /etc/default/grub
        sudo arch-chroot "$mount_root" env PATH="$debian_path" mkdir -p /boot/grub/
        sudo arch-chroot "$mount_root" env PATH="$debian_path" \
            cp /usr/lib/grub/x86_64-pc/stage1 \
               /usr/lib/grub/x86_64-pc/e2fs_stage1_5 \
               /usr/lib/grub/x86_64-pc/stage2 \
               /boot/grub
        cat << EOF | sudo arch-chroot "$mount_root" env PATH="$debian_path" tee /boot/grub/menu.lst >/dev/null
default             0
timeout             2

title               GNU/Linux, kernel 2.6.24, nographic
root                (hd0,1)
kernel              /boot/vmlinuz-linux root=/dev/hda2 ro console=ttyS0 nokaslr
initrd              /boot/initramfs-linux.img
#savedefault

title               GNU/Linux, kernel 2.6.24
root                (hd0,1)
kernel              /boot/vmlinuz-linux root=/dev/hda2 ro nokaslr
initrd              /boot/initramfs-linux.img
#savedefault
EOF

        cat << EOF | sudo arch-chroot "$mount_root" env PATH="$debian_path" tee /root/install_grub.sh >/dev/null
#!/bin/bash
cat << EOF_GRUB | grub --batch
device (hd0) /dev/hda
root (hd0,1)
cat /boot/grub/menu.lst
setup (hd0)
quit
EOF_GRUB
EOF
        chmod +x /root/install_grub.sh

    fi


    _umount
    _fsck
    _disconnect
}

main(){
    # zsh: main
    # bash: bash
    if [ "$(basename "$0")" != "debian-4.sh" ];then
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

