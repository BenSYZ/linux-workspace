2.6.24 中 pivot_root 始终不能 pivot_root

从 function comment 中看到

> Also, the current root cannot be on the 'rootfs' (initial ramfs) filesystem.
> See Documentation/filesystems/ramfs-rootfs-initramfs.txt for alternatives
> in this situation.

Documentation/filesystems/ramfs-rootfs-initramfs.txt

>  - When switching another root device, initrd would pivot_root and then
>  umount the ramdisk.  But initramfs is rootfs: you can neither pivot_root
>  rootfs, nor unmount it.  Instead delete everything out of rootfs to
>  free up the space (find -xdev / -exec rm '{}' ';'), overmount rootfs
>  with the new root (cd /newmount; mount --move . /; chroot .), attach
>  stdin/stdout/stderr to the new /dev/console, and exec the new init.

>  Since this is a remarkably persnickity process (and involves deleting
>  commands before you can run them), the klibc package introduced a helper
>  program (utils/run_init.c) to do all this for you.  Most other packages
>  (such as busybox) have named this command "switch_root".

是在查验 mnt 时失败，细节不清楚


总之：

* pivot_root 不能在 ramfs 和 new_root 中使用
* switch_root 是
    1. 删除 / 下的所有
    2. 将 new_root/ mount move 到 /
