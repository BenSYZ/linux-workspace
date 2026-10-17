## for xx.o.cmd
```
./gen_compile_commands.py
```

## for bear

```sh
rm -f /tmp/build_log.txt
export CC=$(realpath ./bin/gcc)
make -j$(nproc)

cat /tmp/build_log.txt | bear parse-sh
```

