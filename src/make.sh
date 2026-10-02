#!/bin/bash -e
main(){
    cd ./linux
    make -j"$(nproc)"
    make compile_commands.json
    make scripts_gdb
    make tags
    ccls --index=. --init="{\"cache\": {\"directory\": \"$HOME/.cache/ccls\"}}" --log-file=/tmp/ccls_full_init.log -v=1

    return 0
}
main "$@"

