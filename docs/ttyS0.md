在现代使用 systemd 的 Linux 系统（如 Arch Linux）中，内核启动参数中的 console= 会直接触发并启动 serial-getty。

ttyS0 由 serial-getty@ttyS0.service 启动不要起 getty@ttyS0
