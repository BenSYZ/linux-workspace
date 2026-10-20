## official grub
stat 等获取磁盘大小的命令有问题，需要 debian 的补丁，所以用不了

```sh
git clone -b grub-legacy --depth=1 https://gitlab.freedesktop.org/gnu-grub/grub.git

./wrapper.sh
    cd grub
    rm -f /tmp/build_log.txt
    export CFLAGS="-O0 -g"
    export LDFLAGS=-static
    export CC=$(realpath ../../build/compile_commands_helper/bin/gcc)
    ./autogen.sh
    ./configure
    make -j$(nproc)
```


## debian grub
* sync by ./sync.sh
* make by ./make.sh

