---
title: "disk interface"
draftDate: 2026-10-09T19:16:52+08:00
date: 2026-10-09T19:16:52+08:00
lastMod: 2026-10-09T19:16:52+08:00
author: "Ben"
draft: false
article: true
code: true
mermaid: false
katex: false
geometry: margin=2cm
CJKmainfont: "Noto Sans CJK SC"
description: "disk interface"
tags: [ "disk", "interface" ]
---

## 硬件接口
* PATA
* SATA

## 软件协议
* ATA：CPU 一条指令一条指令发送
* AHCI：支持 dma，队列，热插拔

SATA 可以：

1. 直接发送 ata 指令，就是 ide 兼容模式。
2. 也支持 ahci 协议

## 设备树
ahci 控制器是位于主板的。

我们能看到的硬盘 pin 针上走的是 ata 指令，相较于 pata，sata 的 pin 更少，但就是 ata

cpu 和 ahci 控制器通讯，ahci 和外部的 sata 盘通讯

-----

## scsi
scsi 相当于是比 ahci 更全的指令集。无论 ata 还是 ahci，都会被 scsi 包裹住提供给 Linux 系统其他部分（block queue unplug 的设备）

SCSI（小型计算机系统接口）除了硬盘之外，还可以连接多种不同类型的外围设备

• 光学存储设备：如 CD-ROM、DVD-ROM 光驱以及光盘刻录机。
• 磁带机与磁带库：早期及企业级备份中极为常见的磁带驱动器（如 DAT、DDS 等）。
• 扫描仪：早期专业级或高解析度彩色/底片扫描仪普遍采用外置 SCSI 接口以保证高速传输。
• 可移动/大容量存储介质：如 ZIP 驱动器、JAZ 驱动器以及 MO（磁光盘）驱动器。
• 打印机：部分早期工业或大幅面/专业打印设备支持 SCSI 接口。

* PATA: hda
* SCSI: sda
* SATA: none(ata has been developed)

```
➜ realpath /sys/class/scsi_disk/0:0:0:0
/sys/devices/pci0000:00/0000:00:17.0/ata1/host0/target0:0:0/0:0:0:0/scsi_disk/0:0:0:0
➜ lspci
00:17.0 SATA controller: Intel Corporation Sunrise Point-LP SATA Controller [AHCI mode] (rev 21)
➜ cat /proc/scsi/scsi
Attached devices:
Host: scsi0 Channel: 00 Id: 00 Lun: 00
  Vendor: ATA      Model: WDC  WDS200T2B0A Rev: 20WD
  Type:   Direct-Access                    ANSI  SCSI revision: 05
```

设备实际还是挂在物理总线上，但是被 scsi 封装了。scsi 是一个协议头。


----

• PATA(老IDE) / SATA / AHCI ➔ 走 SCSI 包裹通道 ➔ 命名为 /dev/sdX
Linux 内核通过 libata 架构，将它们的 ATA 指令全部包装成 SCSI 指令进行统一管理。
• VirtIO-SCSI (QEMU方案二) ➔ 走真·SCSI 通道 ➔ 命名为 /dev/sdX
虚拟机里的高级控制器，它直接在虚拟化通道里传输 SCSI 指令，不需要 libata 翻译，极其高效。
• VirtIO-Blk (QEMU默认) ➔ 走纯虚拟化扁平通道 ➔ 命名为 /dev/vdX
为了追求极致速度，直接把 SCSI 和 ATA 的包袱全扔掉。操作系统通过定制驱动（virtio_blk）和 QEMU 后端进行最纯粹的块数据对话。
• NVMe (现代物理机 M.2 固态) ➔ 走全新 PCIe 原生通道 ➔ 命名为 /dev/nvmeXnX
因为 AHCI 和 SCSI 的队列设计在面对超高速闪存时都嫌慢了，现代固态硬盘彻底起兵造反，既不走 ATA 也不走 SCSI。它用全新的 NVMe 指令集和多达 64000 个队列，直接和 PCIe 总线对话。所以它在 Linux 里拥有了独立的、专属于新时代的尊贵命名！

nvme 的指令都完全是独立的，完全没有使用 ata 指令集


