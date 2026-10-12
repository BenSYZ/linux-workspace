```
primary device
[    0.841115] fbcon: virtio_gpudrmfb (fb0) is primary device
[    0.841115] fbcon: virtio_gpudrmfb (fb0) is primary device
[    0.875455] virtio-pci 0000:00:03.0: [drm] fb0: virtio_gpudrmfb frame buffer device
```


```
#0  fbcon_select_primary (info=0xffff88807e503c00) at drivers/video/fbdev/core/fbcon.c:2955
#1  do_fb_registered (info=0xffff88807e503c00) at drivers/video/fbdev/core/fbcon.c:2998
#2  fbcon_fb_registered (info=info@entry=0xffff88807e503c00) at drivers/video/fbdev/core/fbcon.c:3038
#3  0xffffffff81981010 in do_register_framebuffer (fb_info=fb_info@entry=0xffff88807e503c00) at drivers/video/fbdev/core/fbmem.c:538
#4  0xffffffff81981120 in register_framebuffer (fb_info=fb_info@entry=0xffff88807e503c00) at drivers/video/fbdev/core/fbmem.c:605
#5  0xffffffff81b1197d in __drm_fb_helper_initial_config_and_unlock (fb_helper=fb_helper@entry=0xffff88807f006e00) at drivers/gpu/drm/drm_fb_helper.c:1746
#6  0xffffffff81b11bc8 in drm_fb_helper_initial_config (fb_helper=0xffff88807f006e00) at drivers/gpu/drm/drm_fb_helper.c:1808
#7  drm_fb_helper_initial_config (fb_helper=fb_helper@entry=0xffff88807f006e00) at drivers/gpu/drm/drm_fb_helper.c:1800
#8  0xffffffff81b17812 in drm_fbdev_client_hotplug (client=0xffff88807f006e00) at drivers/gpu/drm/clients/drm_fbdev_client.c:74
#9  0xffffffff81af42f5 in drm_client_register (client=client@entry=0xffff88807f006e00) at drivers/gpu/drm/drm_client.c:143
#10 0xffffffff81b17978 in drm_fbdev_client_setup (dev=dev@entry=0xffff88807e5fd800, format=<optimized out>) at drivers/gpu/drm/clients/drm_fbdev_client.c:176
#11 0xffffffff81b1690b in drm_client_setup (dev=0xffff88807e5fd800, format=0x0) at drivers/gpu/drm/clients/drm_client_setup.c:46
#12 drm_client_setup (dev=0xffff88807e5fd800, format=format@entry=0x0) at drivers/gpu/drm/clients/drm_client_setup.c:35
#13 0xffffffff81d69c18 in virtio_gpu_probe (vdev=0xffff88807e5ff000) at drivers/gpu/drm/virtio/virtgpu_drv.c:111
#14 0xffffffff81a1e973 in virtio_dev_probe (_d=0xffff88807e5ff010) at drivers/virtio/virtio.c:347
#15 0xffffffff81d838e0 in call_driver_probe (dev=0xffff88807e5ff010, drv=0xffffffff8300d960 <virtio_gpu_driver>) at drivers/base/dd.c:628
#16 really_probe (dev=dev@entry=0xffff88807e5ff010, drv=drv@entry=0xffffffff8300d960 <virtio_gpu_driver>) at drivers/base/dd.c:706
#17 0xffffffff81d83b40 in __driver_probe_device (drv=drv@entry=0xffffffff8300d960 <virtio_gpu_driver>, dev=dev@entry=0xffff88807e5ff010)
    at drivers/base/dd.c:868
#18 0xffffffff81d83d1f in driver_probe_device (drv=drv@entry=0xffffffff8300d960 <virtio_gpu_driver>, dev=dev@entry=0xffff88807e5ff010) at drivers/base/dd.c:898
#19 0xffffffff81d83f04 in __driver_attach (dev=0xffff88807e5ff010, data=0xffffffff8300d960 <virtio_gpu_driver>) at drivers/base/dd.c:1292
#20 __driver_attach (dev=0xffff88807e5ff010, data=0xffffffff8300d960 <virtio_gpu_driver>) at drivers/base/dd.c:1232
#21 0xffffffff81d80dd2 in bus_for_each_dev (bus=<optimized out>, start=start@entry=0x0, data=data@entry=0xffffffff8300d960 <virtio_gpu_driver>,
    fn=fn@entry=0xffffffff81d83e70 <__driver_attach>) at drivers/base/bus.c:383
#22 0xffffffff81d8330d in driver_attach (drv=drv@entry=0xffffffff8300d960 <virtio_gpu_driver>) at drivers/base/dd.c:1310
#23 0xffffffff81d827e8 in bus_add_driver (drv=drv@entry=0xffffffff8300d960 <virtio_gpu_driver>) at drivers/base/bus.c:763
#24 0xffffffff81d84e64 in driver_register (drv=drv@entry=0xffffffff8300d960 <virtio_gpu_driver>) at drivers/base/driver.c:174
#25 0xffffffff81a1e013 in __register_virtio_driver (driver=driver@entry=0xffffffff8300d960 <virtio_gpu_driver>, owner=owner@entry=0x0)
    at drivers/virtio/virtio.c:478
#26 0xffffffff8317c68d in virtio_gpu_driver_init () at drivers/gpu/drm/virtio/virtgpu_drv.c:298
#27 0xffffffff81278b80 in do_one_initcall (fn=0xffffffff8317c630 <virtio_gpu_driver_init>) at init/main.c:1362
#28 0xffffffff8311b352 in do_initcall_level (level=6, command_line=0xffff8880042bcd00 "BOOT_IMAGE") at init/main.c:1424
#29 do_initcalls () at init/main.c:1440
#30 do_basic_setup () at init/main.c:1460
#31 kernel_init_freeable () at init/main.c:1675
#32 0xffffffff8247b1ee in kernel_init (unused=<optimized out>) at init/main.c:1565
#33 0xffffffff812c0031 in ret_from_fork (prev=<optimized out>, regs=0xffffc9000001ff58, fn=0xffffffff8247b1d0 <kernel_init>, fn_arg=0x0)
    at arch/x86/kernel/process.c:158
#34 0xffffffff8127953a in ret_from_fork_asm () at arch/x86/entry/entry_64.S:245
```



Documentation/arch/x86/boot.rst
Documentation/fb/fbcon.rst



```
hbreak start_kernel
break fbcon_select_primary
break register_framebuffer
break virtio_gpu_probe
break drm_client_setup
break drm_client_register
break drm_log_draw_line
break drm_log_write_thread
break drm_log.c:448
```
