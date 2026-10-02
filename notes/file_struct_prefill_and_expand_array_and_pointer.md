as I remember in linux 2.6.24, there are two members describe one thing: one is array, one is pointer

in linux 7:
```c
struct files_struct {
  /*
   * read mostly part
   */
	atomic_t count;
	bool resize_in_progress;
	wait_queue_head_t resize_wait;

	struct fdtable __rcu *fdt;
	struct fdtable fdtab;
  /*
   * written part on a separate cache line in SMP
   */
	spinlock_t file_lock ____cacheline_aligned_in_smp;
	unsigned int next_fd;
	unsigned long close_on_exec_init[1];
	unsigned long open_fds_init[1];
	unsigned long full_fds_bits_init[1];
	struct file __rcu * fd_array[NR_OPEN_DEFAULT];
};
```

are they correponds to fd_array (quick path, prefill) and fdt->fd(slow path)

```c
struct files_struct init_files = {
	.count		= ATOMIC_INIT(1),
	.fdt		= &init_files.fdtab,
	.fdtab		= {
		.max_fds	= NR_OPEN_DEFAULT,
		.fd		= &init_files.fd_array[0],
		.close_on_exec	= init_files.close_on_exec_init,
		.open_fds	= init_files.open_fds_init,
		.full_fds_bits	= init_files.full_fds_bits_init,
	},
	.file_lock	= __SPIN_LOCK_UNLOCKED(init_files.file_lock),
	.resize_wait	= __WAIT_QUEUE_HEAD_INITIALIZER(init_files.resize_wait),
};
```

these initial code reveals what I said 
