# gdb -x ./.gdbinit
cd_source /home/ben/.config/gdb/linux/2.6.24/2.6.24.gdb
set-autoedit-socket "2.6.24"

directory ../src/linux

#symbol-file ../../src/linux/vmlinux -readnow
symbol-file ../src/linux/vmlinux -readnow
set-target .gdb.sock

add-auto-load-safe-path ../src/linux
source ../src/linux/vmlinux-gdb.py

set history filename ./.gdb_history

hbreak start_kernel

