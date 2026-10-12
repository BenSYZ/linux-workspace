https://www.redhat.com/en/blog/introduction-virtio-networking-and-vhost-net

## what is virtio

> Virtio was developed as a standardized open interface for virtual machines (VMs) to access simplified devices such as block devices and network adaptors.

## virtio 的两端

virtio 分 vhost/virtio

* vhost 是 host 这边对设备的模拟
* virtio 是 gust 对设备的驱动

## control/data plane

* control plane：建链、中断（大规模数据来时，可以使用 polling）等
* data plane：大规模的数据传输，采用 ring buffer，shared memory
