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

<!--

```sh
./wrapper.sh
    cd grub/grub
    rm -f /tmp/build_log.txt
    export CFLAGS="-O0 -g"
    export LDFLAGS=-static
    export CC=$(realpath ../../build/compile_commands_helper/bin/gcc)
    export CC=$(realpath ../../../build/compile_commands_helper/bin/gcc)
    ./autogen.sh
    ./configure
    make -j$(nproc)
```
-->

```sh
mount_root="../build/debian-4"
debian_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

sudo mkdir -p "$mount_root"/"$PWD"/
sudo mount --bind "$PWD"/.. "$mount_root"/"$PWD"/..
sudo arch-chroot "$mount_root" env PATH="$debian_path" /bin/bash -c "cd \"$PWD\" && exec /bin/bash"
    mkdir grub
    cd grub
    apt-get build-dep grub
    apt-get source grub
    cd grub-0.97

    export DEB_BUILD_OPTIONS=-noopt
    export PATH="$PWD/../../../build/compile_commands_helper/bin/:$PATH"
    #dpkg-buildpackage -us -uc
    ./debian/rules build
    mv /tmp/build_log.txt ../

sudo umount "$mount_root"/"$PWD"/..
sudo chown -R $USER:$USER grub


############# recompile:

mount_root="../build/debian-4"
debian_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

sudo mount --bind "$PWD"/.. "$mount_root"/"$PWD"/..
sudo arch-chroot "$mount_root" env PATH="$debian_path" /bin/bash -c "cd \"$PWD\" && exec /bin/bash"
    cd grub/grub-0.97
    export DEB_BUILD_OPTIONS=-noopt
    export PATH="$PWD/../../../build/compile_commands_helper/bin/:$PATH"
    #dpkg-buildpackage -us -uc
    ./debian/rules build
    mv /tmp/build_log.txt ../

sudo umount "$mount_root"/"$PWD"/..
sudo chown -R $USER:$USER grub
```


```sh
cd grub/grub-0.97
cat ../build_log.txt | bear parse-sh
```
