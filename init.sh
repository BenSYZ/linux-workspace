#!/bin/bash
main(){
    make -C ./run/linux/rootfses
    cd ./build/ && ./rootfs.sh && sudo mount rootfs.img debian-4
    cd ../

    return 0
}
main "$@"

