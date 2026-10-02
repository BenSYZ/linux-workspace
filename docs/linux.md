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


