#!/bin/bash
main(){
    cd ./grub/grub-0.97 || exit 1
    export DEB_BUILD_OPTIONS=-noopt
    export PATH="$PWD/../../../../build/compile_commands_helper/bin/:$PATH"
    export LOGNAME=root
    #dpkg-buildpackage -us -uc
    fakeroot ./debian/rules "${@:-build}"
    mv /tmp/build_log.txt ../
    return 0
}
main "$@"

