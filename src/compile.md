## Linux

```sh
./wrapper.sh
    cd ./linux
    make defconfig
    make menuconfig
    make -j$(nproc)
```

```sh
cd linux
../../build/compile_commands_helper/gen_compile_commands.py
```

## grub

```sh
./wrapper.sh
    cd grub/grub
    rm -f /tmp/build_log.txt
    export CFLAGS=-O0
    export CC=$(realpath ../../../build/compile_commands_helper/bin/gcc)
    ./autogen.sh
    ./configure
    make -j$(nproc)
```

```sh
cd grub
cat /tmp/build_log.txt | bear parse-sh
```
