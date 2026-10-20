## 关于 mount -l 显示 rootfs 而不是实际的分区，而 installed 的就没问题

mount -l 是看 /etc/mtab /proc/mounts

现代的 /etc/mtab 指向 ../proc/self/mounts

mount -l 显示根目录挂载的设备是 rootfs 这不是 init 操作的问题，2.6.24 本身 pivot_root 不能用于 ramfs，所以 / 永远无法卸载

查看 /proc/mounts 会发现：不管是自己的 initramfs 还是 installed 都有两个挂载 /

区别在 installed 的版本有 /etc/fstab，/etc/init.d 下的这几个配置文件会根据 /etc/fstab 将 rootfs 移除

```
find /etc -type f -exec grep -H mtab \;
/etc/init.d/checkroot.sh
/etc/init.d/mtab.sh
/etc/init.d/umountnfs.sh
/etc/init.d/udev-mtab
```

## monut failed

没 hda 的驱动：
 mount: Mounting /dev/hda1 on /root failed: No such file or directory

Inode 大小不对
 mount: Mounting /dev/hda1 on /root failed: Invalid argument

sudo mkfs.ext3 -I 128 /dev/nbd0p1

## respawning too fast
INIT: Id "2" respawning too fast: disabled for 5 minutes
INIT: Id "3" respawning too fast: disabled for 5 minutes
INIT: Id "4" respawning too fast: disabled for 5 minutes
INIT: Id "5" respawning too fast: disabled for 5 minutes
INIT: Id "6" respawning too fast: disabled for 5 minutes

tty crash
