git clone -b grub-legacy --depth 1 https://gitlab.freedesktop.org/gnu-grub/grub.git


```
# grub need boot partition as bios INT 13h can only find first 8G (by LLM)
or in install stage: it will complains:
Error 18: Selected cylinder exceeds maximum supported by BIOS
```


## grub error

```
Error 18: Selected cylinder exceeds maximum supported by BIOS
```

1. 没权限
2. 拼接出错
    * grub: lib/device.c:1121: sprintf (dev + strlen(dev), "%d", ((partition >> 16) & 0xFF) + 1);
    * works for sda and sda1
    * but not work for /dev/nbd0 /dev/nbd0p1
3. 启动分区不在第一个
    lib/device.c: get_partition_table_geometry 判断是 bad 时，上层走 default

实测：menu.lst 写在 63~64 grub 无所谓的

### LLM: disk size limit

位 (Bit):   7   6   5   4   3   2   1   0
          +---+---+---+---+---+---+---+---+
含义:     |C9 |C8 |S5 |S4 |S3 |S2 |S1 |S0 |
          +---+---+---+---+---+---+---+---+
          \_____/ \_____________________/
         柱面高2位         扇区低6位

CHS 寻址总共消耗 24 位（3个字节）。它们的空间占用被分配给不同的硬件维度：
• 磁头（Heads）：占用 8 位。最大值 2⁸ = 256（实际由于限制，通常最大为 255）。
• 扇区（Sectors）：占用 6 位。最大值 2⁶ - 1 = 63（扇区编号从 1 开始，0 留空不用）。
• 柱面（Cylinders）：占用 10 位。最大值 2¹⁰ = 1024（编号 0 ~ 1023）。

把这三个硬件维度的寻址上限相乘，就能得到这个体系能管理的最大扇区总数：

\(\text{最大扇区数}=1024\text{\ (柱面)}\times 255\text{\ (磁头)}\times 63\text{\ (扇区)}=16,450,560\text{ 个扇区}\)

传统 CHS 能够管理的最大磁盘容量

因为每个扇区代表 512 字节（即 0.5 KiB），所以将最大扇区数乘以扇区大小，就是整个传统 CHS 寻址能够触碰到的天花板：

\(16,450,560\times 512\text{ 字节}\approx 8,422,686,720\text{ 字节}\approx \mathbf{7.84}\text{\ GiB}\)

这就是早期计算机硬件历史上有名的 8.4 GB 限制（常称 8.2G 或 8.4G 墙）。一旦当年硬盘容量超过 8.4 GB，老式 BIOS 的 CHS 寻址就彻底抓瞎，无法访问超出部分。
