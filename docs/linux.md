## DEBUG:

* DEBUG_INFO
    * deps: DEBUG_INFO_DWARF5
* FRAME_POINTER
    * deps: UNWINDER_FRAME_POINTER
* CONFIG_GDB_SCRIPTS
    * make scripts_gdb
* CONFIG_RANDOMIZE_BASE=n
    * KASLR(Kernel Address Space Layout Randomization)
* CONFIG_DEBUG_INFO_REDUCED=n

----

二选一，都得优化
    * CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
    * CONFIG_CC_OPTIMIZE_FOR_SIZE

## display:
### qemu default VGA:
* CONFIG_DRM_BOCHS

### virtio VGA (`-device virtio-vga`)
* CONFIG_DRM_VIRTIO_GPU

## framebuffer and tty0

search CONFIG_VGA_CONSOLE

* CONFIG_FB
* CONFIG_FRAMEBUFFER_CONSOLE
* CONFIG_DRM_FBDEV_EMULATION: drm simulate fb dev

* CONFIG_DRM_CLIENT_LOG: boot log
* CONFIG_DRM_CLIENT_DEFAULT_FBDEV: boot log to fb
    * drm_client_setup 会去初始化 fbdev 如果是 log 则没有 fb，why???(./TODO/fb_dev.md)

https://unix.stackexchange.com/questions/631224/how-can-i-enable-tty-console


## config.gz
* CONFIG_IKCONFIG
* CONFIG_IKCONFIG_PROC


---
KGDB 用于 Linux 跑在板子上，通过内核启动参数 `kgdboc=<device>,<baud_rate>` 远程调试

https://share.google/aimode/ubE86dIXpiOWRXkfX

## gdb
```
# 不要用 scripts/gdb/vmlinux-gdb.py，路径会有问题。用根目录的 vmlinux-gdb.py
source ../../src/linux/vmlinux-gdb.py
```


## edit
../src/linux/scripts/clang-tools/gen_compile_commands.py

make compile_commands.json
make tags





---

## OUTPUT

export KBUILD_OUTPUT=$PWD/build
or
make O=$PWD/build


