#target remote localhost:9876
#set architecture i8086
set-target localhost:9876

symbol-file

#cd_source ./gdb/grub_stage1.gdb
#cd_source ./gdb/grub_stage2.gdb

#cd_source ./gdb/bzImage_as_disk.gdb

#cd_source ./gdb/boot_vmlinux.gdb
cd_source ./gdb/kernel_vmlinux.gdb

#source write.gdb
#source tmp.gdb

set-autoedit-socket "grub"

#define ni
# nexti
# x/i $cs*16+$eip
#end
#define x_ip
# x/i $cs*16+$eip
#end
