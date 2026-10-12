
## listen unix socket
https://share.google/aimode/XIPVm8tLsmY0L6TOg

为什么 UNIX Socket 必须显式创建 -chardev？
UNIX Socket 和 TCP 在内核层面的管理方式不同：
1. 它是一个真实的文件：UNIX Socket 必须在你的 Linux 文件系统中创建一个实实在在的 .sock 文件（例如 /tmp/qemu-gdb.sock）。
2. 需要复杂的内核参数配置：QEMU 必须明确知道：
	• 这个文件应该创建在哪里（path=...）？
	• 谁是服务端、谁是客户端（server=on）？
	• 如果 GDB 还没打开，QEMU 启动时要不要卡住死等它（wait=off）？

## packages
* qemu-system-x86: base
* qemu-desktop: with virtio-vga and other display virtio devices


## command
ctrl+a c 切换 (qemu)
info qtree 查看 device tree


## id bus
在 QEMU 的设备树（Device Tree）中，id 和 bus 是全局通用的对象定位符：

* id=： 任何设备都可以指定一个 id，用来作为它的唯一标识符。
* bus=： 挂载子设备时，用来指定父级总线的 id。

## storage

https://share.google/aimode/8RVCTODtnTvlHJQCl

https://share.google/aimode/NThPsCRuUHi8zBy1W

qemu 的 storage

```
man qemu
   Block device options
The most explicit way to describe disks is to use a combination of -device to specify the hardware device and -blockdev to describe the backend.  The  device  defines what the guest sees and the backend describes how QEMU handles the data. It is the only guaranteed stable interface for describing block devices and as such is recommended for management tools and scripting.
```

```
➜ qemu-system-x86_64 -device help
➜ qemu-system-x86_64 -device virtio-vga,help
```

### blockdev

QEMU 的块设备架构设计为：设备层 (Device) → 格式层 (Format) → 协议层 (Protocol)。

• ide-hd 是设备层。
• raw / qcow2 是格式层。
• file / nbd / iscsi 是协议层。

#### raw disk

```
-blockdev driver=file,node-name=disk_file,filename=./rootfses/arch.img
-blockdev driver=raw,node-name=disk,file=disk_file
```

我可以直接用 file，

```
-blockdev driver=file,node-name=disk_file,filename=./rootfses/arch.img
-blockdev driver=raw,node-name=disk,file=disk_file
-device driver=ich9-ahci,id=my_sata_card,addr=04.0
-device driver=ide-hd,drive=disk,bus=my_sata_card.0

-blockdev driver=file,node-name=disk_file,filename=./rootfses/arch.img
-device driver=ich9-ahci,id=my_sata_card,addr=04.0
-device driver=ide-hd,drive=disk_file,bus=my_sata_card.0
```

但后一种写法少了 raw，和 qcow2 不能对应了，显式加上 raw 可以保持配置的层级清晰，方便随时切换为 qcow2。


```
-blockdev driver=file,node-name=disk_file,filename=./rootfses/arch.qcow2
-blockdev driver=qcow2,node-name=disk,file=disk_file
-device driver=ich9-ahci,id=my_sata_card,addr=04.0
-device driver=ide-hd,drive=disk,bus=my_sata_card.0
```


host/slave 可以通过 dd 互相发送读取数据


#### qcow2 disk
qcow2 dev 需要分层

-blockdev 的设计是将块设备（网卡/磁盘后端）拆成多层（Layered）。一个 qcow2 镜像在 QEMU 看来包含两层：

1. 格式层 (Format)：负责解析 qcow2 的快照、加密、簇（Clusters）。
2. 协议层 (Protocol)：负责底层的数据读写（在你的场景里是一个本地 file，但也可以是 nbd, iscsi 等）。

```
# 1. 定义底层：它是一个本地文件协议层 (Protocol)
-blockdev driver=file,node-name=disk_file,filename=./rootfses/arch.qcow2
# 2. 定义上层：它是一个格式层 (Format)，它的底层支撑 (file) 指向上面定义的节点
-blockdev driver=qcow2,node-name=disk,file=disk_file
```

以上 1 2 可以合并写成

```
-blockdev driver=qcow2,node-name=disk,file.filename=./rootfses/arch.qcow2,file.driver=file
# 或
-drive file=./rootfses/arch.qcow2,format=qcow2,id=disk_qcow2,if=none
```

driver = blockdev + device + connect on bus
driver + if=none = blockdev + device

但不推荐



### device


```
    ## 2. 在 PCIe 总线上开辟一个现代的扩展插槽 (PCIe Root Port)
    #-device driver=pcie-root-port,id=pcie_port1,chassis=1,slot=1
    ## 3. 买一张 ICH9 AHCI (SATA) 扩展卡，插在这个 PCIe 插槽上
    #-device driver=ich9-ahci,id=my_sata_card,bus=pcie_port1,addr=00.0
    ## 4. 把 SATA 硬盘插在这张扩展卡的第一个端口上
    #-device driver=ide-hd,drive=disk_backend,bus=my_sata_card.0
```

#### ide 硬盘
`-drive file=./rootfses/arch.qcow2`

```
[root@qemu-arch-a67856f7 ~]# dmesg |grep -E '[^dD]ata|sda'
[    0.000000] Command line: console=ttyS0 nokaslr root=/dev/sda2 init=/bin/bash
[    0.048037] Kernel command line: console=ttyS0 nokaslr root=/dev/sda2 init=/bin/bash
[    0.641670] libata version 3.00 loaded.
[    0.839020] scsi host0: ata_piix
[    0.840449] scsi host1: ata_piix
[    0.840496] ata1: PATA max MWDMA2 cmd 0x1f0 ctl 0x3f6 bmdma 0xc040 irq 14 lpm-pol 0
[    0.840498] ata2: PATA max MWDMA2 cmd 0x170 ctl 0x376 bmdma 0xc048 irq 15 lpm-pol 0
[    1.015157] ata2: found unknown device (class 0)
[    1.015886] ata1: found unknown device (class 0)
[    1.022497] ata1.00: Model 'QEMU HARDDISK', rev '2.5+', applying quirks: bridgeok
[    1.022521] ata1.00: ATA-7: QEMU HARDDISK, 2.5+, max UDMA/100
[    1.022524] ata1.00: 134217728 sectors, multi 16: LBA48
[    1.031815] ata2.00: ATAPI: QEMU DVD-ROM, 2.5+, max UDMA/100
[    1.036752] sd 0:0:0:0: [sda] 134217728 512-byte logical blocks: (68.7 GB/64.0 GiB)
[    1.036759] sd 0:0:0:0: [sda] Write Protect is off
[    1.036760] sd 0:0:0:0: [sda] Mode Sense: 00 3a 00 00
[    1.036765] sd 0:0:0:0: [sda] Write cache: enabled, read cache: enabled, doesn't support DPO or FUA
[    1.036774] sd 0:0:0:0: [sda] Preferred minimum I/O size 512 bytes
[    1.071958]  sda: sda1 sda2
[    1.072100] sd 0:0:0:0: [sda] Attached SCSI disk

[root@qemu-arch-a67856f7 ~]# lspci
00:00.0 Host bridge: Intel Corporation 440FX - 82441FX PMC [Natoma] (rev 02)
00:01.0 ISA bridge: Intel Corporation 82371SB PIIX3 ISA [Natoma/Triton II]
00:01.1 IDE interface: Intel Corporation 82371SB PIIX3 IDE [Natoma/Triton II]
00:01.3 Bridge: Intel Corporation 82371AB/EB/MB PIIX4 ACPI (rev 03)
00:02.0 VGA compatible controller: Device 1234:1111 (rev 02)
00:03.0 Ethernet controller: Intel Corporation 82540EM Gigabit Ethernet Controller (rev 03)
```

这里用了一个 piix3 的 pcie 到 ide 的转接卡。

在不启用 efi `pflash` 时，它会被 libata 转成 sda，但是 pflash 和 ide 硬盘兼容性似乎不好，所以没有了。。。


info qtree 可以看到当前 machine 默认有两个 ide.0 ide.1，就是挂在那里

```
# ata backend
-device driver=ide-hd,drive=disk,bus=ide.0
# 或者 ide.1
# 对应 ata1 和 ata2
```


##### 手动分配 piix3-ide

```
# pcie -> ata
-device driver=piix3-ide,id=ata_card,addr=04.0
# ata backend
-device driver=ide-hd,drive=disk,bus=ata_card.0
```

```
[   94.032165] ata1: lost interrupt (Status 0x58)
[   94.685509] ata1.00: limiting speed to PIO4
[   94.685525] ata1.00: exception Emask 0x0 SAct 0x0 SErr 0x0 action 0x6 frozen
[   94.685529] ata1.00: failed command: READ DMA
[   94.685531] ata1.00: cmd c8/00:08:00:00:00/00:00:00:00:00/e0 tag 0 dma 4096 in
[   94.685531]          res 40/00:00:00:00:00/00:00:00:00:00/00 Emask 0x4 (timeout)
[   94.685539] ata1.00: status: { DRDY }
[   94.685746] ata1: soft resetting link
[   94.838424] ata1: found unknown device (class 0)
[   94.841562] ata1.00: configured for PIO4
[   94.841610] ata1: EH complete
[   94.854583]  sda: sda1 sda2
[   94.856197] sd 0:0:0:0: [sda] Attached SCSI disk
```

> Broken Bus Master DMA & Interrupt Routing: In QEMU's PCI/ISA motherboard model (i440FX), the PIIX3 IDE's Bus Master DMA engine and IRQ routing logic are hardcoded to function as an integrated part of PCI device 00:01.0. Moving or creating a second instance at PCI slot 04.0 breaks the legacy IRQ wiring between the PCI INTx lines and the guest's 8259 PIC / IOAPIC.

> why it works
> It downgrades the link mode from DMA to PIO4 (Programmed I/O).
> Why PIO works: Unlike DMA, PIO mode does not rely on hardware interrupt lines to notify the CPU that a block transfer finished. Instead, the CPU manually polls the IDE status register (Status 0x58) byte-by-byte via standard I/O port instructions (inb/outb).

#### virtio 硬盘
vda


```
-drive if=virtio,format=qcow2,file=./rootfses/arch.qcow2
```

```
info qtree
virtio-blk-device
```

```
-device driver=virtio-blk-pci,id=virtio_card,drive=disk
```


#### scsi 硬盘

```
# scsi bus
-device driver=virtio-scsi-pci,id=scsi_bus
# scsi dev
-device driver=scsi-hd,drive=disk,bus=scsi_bus.0
```

### fsdev and 9p

```
    -fsdev local,id=fsdev0,path=/tmp/ben,security_model=mapped
    -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare,id=virtio_card1
```
