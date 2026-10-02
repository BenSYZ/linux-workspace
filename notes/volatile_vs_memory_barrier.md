
https://stackoverflow.com/a/75750900/13033234

https://share.google/aimode/IoILCGGQX4RBZvpf4

https://lwn.net/Articles/793253/

* volatile: 编译器将 C 语言转成 asm 时用 load/store 去内存中读，而不是直接复用上面的寄存器
* memory barrier: 让 CPU 将寄存器中的临时变量同步到内存，一般情况会做一个

## only volatile

对于线程 B，确实是每次从 flag 所在的地址去 load。

但是对于线程 A，CPU 发现 data 和 flag 没有依赖，可能会先执行 flag 再执行 data

```c
volatile int flag = 0;
int data = 0;

// 线程 A (生产者)
data = 42;
flag = 1; 

// 线程 B (消费者)
while (flag == 0); // 以为 volatile 能保证立刻读到 flag 改变
printf("%d", data);
```


## only memory barrier
什么时候“即使有内存屏障，也必须加 volatile”呢？

那就是硬件驱动开发（MMIO，内存映射 I/O）。假设某个内存地址 0x40001000 映射的是一个硬件串口的发送寄存器。你往这个地址连续写 3 个字节：

```c
uint32_t *p = (uint32_t *)0x40001000;
*p = 'A';  // 写入 A
*p = 'B';  // 写入 B
*p = 'C';  // 写入 C
```

如果只加内存屏障：编译器可能会觉得：“你这个人好奇怪，连续给同一个内存地址赋值 A、B、C，那我干脆把前两次优化掉，只生成写 C 的指令吧！”（虽然内存屏障能防乱序，但防不住编译器合并同地址写操作）。

