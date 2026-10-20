#!/bin/bash
main(){
    # by inner_sync
    if ! [ -e ./grub/.sync_done ];then
        "./sync.sh"
    fi

    ../wrapper.sh /bin/bash -c "cd \"$PWD\" && exec ./inner_make.sh $*"

    cd grub/grub-0.97 || exit 1
    cat ../build_log.txt | bear parse-sh
    return 0
}
main "$@"

