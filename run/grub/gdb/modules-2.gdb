##set $head = &modules
##set $curr = modules.next
##while $curr != $head
##    set $mod = (struct module *)((char *)$curr - (size_t)&((struct module *)0)->list)
##    printf "%s %u 0x%lx\n", $mod->name, $mod->mem[0].size, (unsigned long)$mod->mem[0].base
##    set $curr = $curr->next
##end
#
#define get_modules_info
#    set $kernel_obj_dir = $arg0
#    set $final_modules_scripts = $arg1
#
#    printf "%s %s\n", $kernel_obj_dir, $final_modules_scripts
#    set $head = &modules
#    set $curr = modules.next
#    while $curr != $head
#        set $mod = (struct module *)((char *)$curr - (size_t)&((struct module *)0)->list)
#        printf "%s %u 0x%lx\n", $mod->name, $mod->core_size, (unsigned long)$mod->module_core
#        set $curr = $curr->next
#    end
#end
#
#define load_modules
#    set $kernel_obj_dir = "$arg0"
#    set $final_modules_scripts = "/tmp/modules.gdb"
#    printf "%s %s\n", $kernel_obj_dir, $final_modules_scripts
#    pipe get_modules_info $kernel_obj_dir $final_modules_scripts | ./modules-2.sh
#    eval "source %s", $final_modules_scripts
#end

#load_modules "/home/ben/work/linux/linux-2.6.24/src/linux-2.6.24"
load_modules /home/ben/work/linux/linux-2.6.24/src/linux-2.6.24
