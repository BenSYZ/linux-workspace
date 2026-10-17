#!/bin/bash
print_gdb_command(){
    local obj="$1"
    local addr="$2"
    echo "add-symbol-file $obj" -readnow -o "$addr"
}

main(){
    read -r kernel_obj_dir modules_scripts

    #kernel_obj_dir=~/work/linux/linux-2.6.24/src/linux-2.6.24/
    #modules_scripts="/tmp/modules.gdb"
    printf > "$modules_scripts"

    printf "Loading modules...\n" >&2
    this_dir="$(dirname "$(realpath "$0")")"
    cd "$this_dir" || return
    missing_module=()
    echo -n > modules.gdb
    while read -r module _size addr;do
        obj="$(find "$kernel_obj_dir" -name "$module".o  | head -n 1)"
        if [ -z "$obj" ];then
            missing_module+=("$module")
            continue
        fi
        print_gdb_command "$obj" "$addr" >> "$modules_scripts"
    done
    if [ "${#missing_module[@]}" -ne 0 ];then
        printf "Missing modules: %s\n" "${missing_module[*]}" >&2
    fi

    return 0
}
main "$@"

