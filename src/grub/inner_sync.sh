#!/bin/bash -e
main(){
    mkdir -p grub
    cd grub || exit 1
    apt-get build-dep grub
    apt-get source grub
    cd grub-0.97 || exit 1

    export DEB_BUILD_OPTIONS=-noopt
    export PATH="$PWD/../../../../build/compile_commands_helper/bin/:$PATH"
    #dpkg-buildpackage -us -uc
    #./debian/rules build
    #mv /tmp/build_log.txt ../
    touch ../.sync_done
    return 0
}
main "$@"

