#!/bin/bash -e
main(){
    if [ "$#" -gt 0 ];then
        ../wrapper.sh make -C ./linux "$@"
        return 0
    fi
    ../wrapper.sh make -C ./linux -j"$(nproc)"
    ../wrapper.sh make -C ./linux -j"$(nproc)" tags

    ../../build/compile_commands_helper/gen_compile_commands.py -d ./linux -o linux/compile_commands.json
    ccls --index=./linux --init="{\"cache\": {\"directory\": \"$HOME/.cache/ccls\"}}" --log-file=/tmp/ccls_full_init.log -v=1

    return 0
}
main "$@"

