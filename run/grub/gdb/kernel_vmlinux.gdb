directory ../../../src/linux/

# pa
#======

add-symbol-file ../../../src/linux/arch/x86/kernel/head_64.debug.o -readnow -s .text.head 0x200000
# entry: arch/x86/kernel/head_64.S: startup_64
#break *0x200000


# va
#======

# vmlinux does not contains head_64.o's debug info, add this first, or vmlinux will occupy the address
add-symbol-file ../../../src/linux/arch/x86/kernel/head_64.debug.o -readnow -s .text.head 0xffffffff80200000
# 不需要 offset 了，因为 arch/x86/kernel/vmlinux.lds.S 中已经整体将代码偏移到了 __START_KERNEL_map（0xffffffff80000000）
# 0x200131        mov    $0xffffffff8020013a
# 0x200138        jmp    *%rax
# 0x20013a        mov    $0x80000001,%eax
add-symbol-file ../../../src/linux/vmlinux
# entry: arch/x86/kernel/head_64.S: seecondary_startup_64 1f

add-modules-symbol-file ../../../src/linux

#source modules-2.gdb
