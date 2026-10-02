
## listen unix socket
https://share.google/aimode/XIPVm8tLsmY0L6TOg

为什么 UNIX Socket 必须显式创建 -chardev？
UNIX Socket 和 TCP 在内核层面的管理方式不同：
1. 它是一个真实的文件：UNIX Socket 必须在你的 Linux 文件系统中创建一个实实在在的 .sock 文件（例如 /tmp/qemu-gdb.sock）。
2. 需要复杂的内核参数配置：QEMU 必须明确知道：
	• 这个文件应该创建在哪里（path=...）？
	• 谁是服务端、谁是客户端（server=on）？
	• 如果 GDB 还没打开，QEMU 启动时要不要卡住死等它（wait=off）？
