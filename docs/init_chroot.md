## pivot_root 和 switch_root
switch_root 是用户空间的命令，pivot_root 是系统调用

pivot_root 可以移动 ramfs，一切都正常

> - When switching another root device, initrd would pivot_root and then
>   umount the ramdisk.  With nullfs as the true root, pivot_root() works
>   normally from the initramfs.  Userspace can simply do::

>     chdir(new_root);
>     pivot_root(".", ".");
>     umount2(".", MNT_DETACH);

>   This is the preferred method for switching root filesystems.

man switch_root:

> switch_root  moves  already mounted /proc, /dev, /sys and /run to newroot
> and makes newroot the new root filesystem and starts init process.
>
> WARNING: switch_root removes recursively all files and directories on the
> current root filesystem.


关于上面的 example：
### `pivot_root . .`

```
~ # cd new_root/
/new_root # pivot_root . .
/new_root # ls .
bin         home        mnt         root        sys
boot        lib         old_root    run         tmp
dev         lib64       opt         sbin        usr
etc         lost+found  proc        srv         var
/new_root # ls ..
bin       init      proc      sys       usr
dev       new_root  root      tmp
/new_root # ls /
bin         home        mnt         root        sys
boot        lib         old_root    run         tmp
dev         lib64       opt         sbin        usr
etc         lost+found  proc        srv         var
/new_root # cat ../proc/mounts
rootfs / rootfs rw 0 0
proc /proc proc rw,relatime 0 0
dev /dev devtmpfs rw,relatime,size=1010476k,nr_inodes=252619,mode=755 0 0
sys /sys sysfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,relatime 0 0
/dev/sda2 / ext4 rw,relatime 0 0
/dev/sda1 /boot vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro 0 0
/new_root # umount .
umount: can't unmount .: Resource busy
/new_root # umount -l .
/new_root # cat ../proc/mounts
cat: ../proc/mounts: No such file or directory
```

#### Q: 为什么 lazy 可以卸掉，但是 umount 不行

```
fuser -avm old_root
```

* 因为 PID=1 的 fd 0 1 2 还指向老的 console
* 因为 PID=1 的 self 还指向老的 console


```sh
mount --move /proc /new_root/proc
mount --move /sys  /new_root/sys
mount --move /dev  /new_root/dev
mount --move /tmp  /new_root/tmp

# shellcheck disable=2164
cd new_root
pivot_root . .

# S1: free fd in old_root
exec 1>/dev/console
exec 2>/dev/console
exec 0</dev/console

# S2: switch self to new_root
exec /bin/sh
umount ..

exec "$@"
```

这里的目录结构有点混乱，详见 pivot_root new_root new_root/old_root

TODO: check: after exec it will free


#### Q: 为什么 umount . 卸载的是 ..

TODO:

### pivot_root new_root/ new_root/old_root

```sh
pivot_root new_root/ new_root/old_root

mount --move old_root/proc/ proc
mount --move old_root/sys sys
mount --move old_root/dev dev
mount --move old_root/tmp tmp

/usr/bin/fuser -avm old_root

# 释放占用的 old_root
## fd
exec 1>/dev/console
exec 2>/dev/console
exec 0</dev/console
## self
exec /usr/bin/bash

/usr/bin/fuser -avm old_root
```

