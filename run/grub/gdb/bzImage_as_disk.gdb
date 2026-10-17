# Note: use qemu-system-i386 or `next` will step into function
# check bzImage as boot loaders's error message
directory ../../../src/linux
symbol-file ../../../src/linux/arch/x86/boot/setup.elf -readnow
