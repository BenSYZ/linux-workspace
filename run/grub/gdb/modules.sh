#!/bin/bash
proc_modules(){
    cat << EOF
ext2 76048 1 - Live 0xffffffff880d3000
mbcache 13568 1 ext2, Live 0xffffffff880ce000
sd_mod 33536 2 - Live 0xffffffff880c4000
ata_generic 12676 0 - Live 0xffffffff880bf000
ata_piix 26372 1 - Live 0xffffffff880b7000
libata 162864 2 ata_generic,ata_piix, Live 0xffffffff8808e000
scsi_mod 169144 2 sd_mod,libata, Live 0xffffffff88063000
generic 9476 0 [permanent], Live 0xffffffff8805f000
e1000 128704 0 - Live 0xffffffff8803c000
ide_core 144408 1 generic, Live 0xffffffff88017000
thermal 22560 0 - Live 0xffffffff88010000
processor 44520 1 thermal, Live 0xffffffff88004000
fan 9608 0 - Live 0xffffffff88000000
EOF


}
print_gdb_command(){
    local obj="$1"
    local addr="$2"
    echo "add-symbol-file $obj" -readnow -o "$addr"
}

main(){
    this_dir="$(dirname "$(realpath "$0")")"
    cd "$this_dir" || return
    missing_module=()
    echo -n > modules.gdb
    while read -r module addr;do
        obj="$(find ~/work/linux/linux-2.6.24/src/linux-2.6.24/ -name "$module".o  | head -n 1)"
        if [ -z "$obj" ];then
            missing_module+=("$module")
            continue
        fi
        print_gdb_command "$obj" "$addr" | tee -a modules.gdb
    done < <(proc_modules | awk '{print $1" "$NF}')
    echo
    echo "${missing_module[*]}"

    return 0
}
main "$@"

