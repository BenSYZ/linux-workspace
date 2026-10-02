调用栈没有 sys_openat，但是 tags 中有，是为什么？

```
#0  do_sys_open (dfd=-100, filename=0x517209 ".", flags=622592, mode=<optimized out>) at fs/open.c:1422
#1  __do_sys_open (filename=0x517209 ".", flags=622592, mode=<optimized out>) at fs/open.c:1431
#2  __se_sys_open (filename=<optimized out>, flags=<optimized out>, mode=<optimized out>) at fs/open.c:1427
#3  __x64_sys_open (regs=0xffffc900001b7f58) at fs/open.c:1427
#4  0xffffffff8127a0f7 in x64_sys_call (regs=regs@entry=0xffffc900001b7f58, nr=<optimized out>) at ./arch/x86/include/generated/asm/syscalls_64.h:3
#5  0xffffffff8245233e in do_syscall_x64 (regs=0xffffc900001b7f58, nr=<optimized out>) at arch/x86/entry/syscall_64.c:61
#6  do_syscall_64 (regs=0xffffc900001b7f58, nr=2) at arch/x86/entry/syscall_64.c:84
#7  0xffffffff81000130 in entry_SYSCALL_64 () at arch/x86/entry/entry_64.S:121
#8  0x0000000000517209 in ?? ()
#9  0x00000000ffffff52 in ?? ()
#10 0x0000000000000001 in ?? ()
#11 0x0000000000000000 in ?? ()
```

```
sys_openat    fs/open.c    /^SYSCALL_DEFINE4(openat, int, dfd, const char __user *, filename, int, flags,$/;"    r
```

```sh
regex_c=(
	'/^SYSCALL_DEFINE[0-9]([[:space:]]*\([[:alnum:]_]*\).*/sys_\1/'
    #....
)
```
scripts/tags.sh 会做一个 `--regex-c=xxx`

详见 regex(7) 和 wctype(3)
