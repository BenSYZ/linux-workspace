directory ../../../src/linux
## with qemu-system-i386-patched, main can be correctly breaked: one is in grub, one is in setup

## real mode: enable segment
#add-symbol-file ../../../src/linux/arch/x86/boot/setup.elf -readnow -o 0x9000*16
##add-symbol-file ../../../src/linux/arch/x86/boot/header.o -readnow -o 0x9000*16
## entry: arch/x86/boot/header.S: _start
##break *0x90200

add-symbol-file ../../../src/linux/arch/x86/boot/compressed/head_64_debug.o -readnow -s .text.head 0x100000
add-symbol-file ../../../src/linux/arch/x86/boot/compressed/vmlinux.with.debug -readnow -o 0x100000
# entry: arch/x86/boot/compressed/head_64.S: startup_32
#break *0x100000

# startup_64: move boot/vmlinux to end of kernel/vmlinux zone
add-symbol-file ../../../src/linux/arch/x86/boot/compressed/vmlinux.with.debug -readnow -o 0x42b000
# entry: arch/x86/boot/compressed/head_64.S: relocated
#break relocated

#tbreak *0x9020*16
#command
#    load_boot_vmlinux
#end





# origin:
#  ## with qemu-system-i386-patched, main can be correctly breaked: one is in grub, one is in setup
#  add-symbol-file ../../../src/linux/arch/x86/boot/setup.elf -readnow -o 0x9000*16
#  add-symbol-file ../../../src/linux/arch/x86/boot/header.o -readnow -o 0x9000*16
#  add-symbol-file ../../../src/linux/arch/x86/boot/compressed/vmlinux -readnow -o 0x100000
#  # startup_64: move to self to end of vmlinuz zone
#  #add-symbol-file ../../../src/linux/arch/x86/boot/compressed/vmlinux -readnow -o 0x42b000
#  add-symbol-file ../../../src/linux/arch/x86/boot/compressed/vmlinux.with.debug -readnow -o 0x42b000


