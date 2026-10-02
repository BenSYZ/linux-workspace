# gdb -x ./.gdbinit
directory ../src/linux

#symbol-file ../../src/linux/vmlinux -readnow
symbol-file ../src/linux/vmlinux
set-target localhost:1234

add-auto-load-safe-path ../src/linux
source ../src/linux/vmlinux-gdb.py

set history filename ./.gdb_history

hbreak start_kernel

