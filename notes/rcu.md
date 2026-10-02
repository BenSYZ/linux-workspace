as I know, the reader can still read the opening ones. but new open will get the new one, what's such thing and how does this implemented? 

When a writer updates data, old readers (those who already started their read operation) continue safely reading the old version, while new readers (those starting after the update) instantly get the new version. Both versions coexist peacefully in memory for a short time.

how does this thing done with code? the writer replace the pointer and hang the old one. the writer is waiting for readers' unlock to release the hanging memory. the existing read has save the old one's address, so it can access the old one?

```c
void reader_function(void)
{
    struct foo *p;

    rcu_read_lock(); // Marks the start of reading

    // p now holds the memory address of the OLD structure (e.g., 0x1000)
    p = rcu_dereference(global_foo); 

    // Even if the global pointer changes right now, 
    // local variable 'p' still points to 0x1000!
    pr_info("Value: %d\n", p->a); 

    rcu_read_unlock(); // Marks the end of reading
}


int writer_update_function(void)
{
    struct foo *new_p, *old_p;

    // 1. Allocate a brand new structure (e.g., at address 0x2000)
    new_p = kmalloc(sizeof(*new_p), GFP_KERNEL);
    new_p->a = 42;

    // 2. Grab the old pointer (0x1000) and save it locally in 'old_p'
    old_p = rcu_dereference_protected(global_foo, lockdep_is_held(&writer_lock));

    // 3. ATOMIC SWAP: global_foo now points to 0x2000 instead of 0x1000.
    // *New* readers calling rcu_dereference() will now get 0x2000.
    rcu_assign_pointer(global_foo, new_p);

    // 4. WAIT: Block the writer until all pre-existing readers (using 0x1000) finish.
    synchronize_rcu();

    // 5. CLEANUP: Now it is 100% safe to free 0x1000 because no reader can reach it.
    kfree(old_p);

    return 0;
}
```

```c
#include <linux/rcupdate.h>
#include <linux/slab.h>

struct foo {
    int a;
    int b;
};

// Global RCU-protected pointer annotated with __rcu
struct foo __rcu *global_foo;

// --- READER CODE ---
void reader_function(void)
{
    struct foo *p;

    // 1. Enter RCU read-side critical section
    rcu_read_lock();

    // 2. Safely fetch the pointer using rcu_dereference()
    p = rcu_dereference(global_foo);
    if (p) {
        // Safe to read data fields
        pr_info("Values: %d, %d\n", p->a, p->b);
    }

    // 3. Exit RCU read-side critical section
    rcu_read_unlock();
}

// --- WRITER CODE ---
int writer_update_function(void)
{
    struct foo *new_p, *old_p;

    new_p = kmalloc(sizeof(*new_p), GFP_KERNEL);
    if (!new_p)
        return -ENOMEM;

    new_p->a = 42;
    new_p->b = 84;

    // Synchronize updates (typically held by a mutex/spinlock for writers)
    // spin_lock(&writer_lock);

    old_p = rcu_dereference_protected(global_foo, lockdep_is_held(&writer_lock));
    
    // Publish the new pointer atomically
    rcu_assign_pointer(global_foo, new_p);

    // spin_unlock(&writer_lock);

    // Wait for ongoing readers to finish, then free the old structure
    synchronize_rcu();
    kfree(old_p);

    return 0;
}
```


the dereference is a wrapper of readonce to avoid tearing? 

-----

## how rcu works
（存疑，需要看代码，不一定是 cpu 上读信息）

so it **bind the "quiescent state" or context_switch to rcu_read_unlock**? or to say the rcu_read_lock to rcu_read_unlock disable schedue. the between state is like irq off code path.

so what the writer need to do is that just checking quiescent state.

but as we just call rcu_read_lock() without any parameter, how does the unrelated writers know it is file->fdt is locked?

### unrelated writer will wait any rcu_read_lock()

unrelated writers call synchronize_rcu() when the reader is in lock()-unlock(), is this case the unrelated writer will wait for the reader's unlock, as there is also no parameter in synchronize_rcu().

synchronize_rcu will wait all the related/unrelated things in system.

If a reader, even one reading a completely different data structure on another part of the system, is currently sitting inside rcu_read_lock() and rcu_read_unlock(), then that CPU cannot report a quiescent state.

This is why RCU is only used for data structures that are read frequently and updated rarely. If you had writers constantly calling synchronize_rcu(), the system would slow to a crawl because writers would constantly be blocking and waiting for readers.

----

### rcu read deadlock and watch dog
so if someone do lock without unlock. then all the writer in system will not be able to free memory. what a disaster! is there any protect code?

#### The Protection Mechanism: The RCU Stall Detector

To prevent this from becoming a silent, catastrophic system failure, the Linux kernel includes a built-in watchdog called the **RCU CPU Stall Detector**.

* **How it works:** If a grace period takes an abnormally long time (usually defaulting to **21 seconds**), the kernel realizes something is stuck.
* **The Result:** It prints a loud **RCU CPU Stall Warning** into the kernel log (`dmesg`), complete with a full stack trace of the exact CPU or task that is causing the blockage. Depending on kernel configuration, this can even trigger a kernel panic to prevent further damage.
* **Debugging Tools:** Developers use configuration flags like `CONFIG_PROVE_RCU` during testing to automatically catch lock/unlock mismatches and bad usage patterns before code ever reaches production.

---

### Do We Have to Get and Put RCU Quickly?

**Yes, absolutely.** This is one of the strictest rules of writing RCU code.

RCU read-side critical sections must be **as short and fast as possible**.

* **No Sleeping or Blocking:** You **cannot** perform operations that might put a thread to sleep inside an RCU critical section (such as allocating memory with standard flags, performing disk/network I/O, or acquiring a mutex).
* **Why?** If you sleep, you hand the CPU over to other tasks. If preemption is disabled (like in `rcu_read_lock_sched()`), sleeping is outright illegal and will crash the kernel. Even in preemptible RCU, holding a read-side lock open while doing heavy work stalls memory reclamation and blocks writers across the entire system.


#### Best Practice for RCU Readers:

1. Quickly grab the RCU read lock (`rcu_read_lock()`).
2. Fetch the pointer safely (`rcu_dereference()`).
3. Copy data or increment a local reference count if you need to keep using it for a long time.
4. Release the lock immediately (`rcu_read_unlock()`).

Keep it brief, get in, get out, and let the rest of the system flow.

-----
## 多线程和锁
锁保护flag的场景：这项事情只要这个线程来做，不需要其他了，就可以让其他线程放掉跳过就是了。

还有由一个线程加载完，其他线程取结果就是。

### 从锁到 rcu

read(fd_install) 会改 files，write(alloc_fd->expand_fdtable) 也会，正常的设计是 read 打开之后，准备挂到 fdtable 时加锁，做完释放。expand 准备更新新的表前加锁，更新完释放。

现在的做法是：

* read 加锁，做完释放。
* write 等所有的释放。

这样的问题是 read 一直来，write 一直放不掉了，所以在 write 等之前需要设置我在等（files->resize_in_progress），让后续的 read 不再进来。

#### fd_install and fdtable_expand
```
__FD_ADD
  FD_PREPARE
    __FD_PREPARE_INIT
      get_unused_fd_flags
        __get_unused_fd_flags
          alloc_fd
            expand_files
              expand_fdtable
                if (atomic_read(&files->count) > 1)
                  synchronize_rcu();

__FD_ADD
  fd_publish
    fd_install
      rcu_read_lock_sched
```

```c
void fd_install(unsigned int fd, struct file *file)
{
	rcu_read_lock_sched();
	if (unlikely(files->resize_in_progress)) {
		rcu_read_unlock_sched();
		/*
		 * 上面的都不会阻塞，会直接到这里，不能死循环，一直尝试：
		 * rcu_read_lock_sched()
		 * test(files->resize_in_progress
		 * rcu_read_unlock_sched()
		 * 所以这里就走 slowpath，锁 files->file_lock
		 */
		fd_install_slowpath(fd, file);
		return;
	}
	rcu_read_unlock_sched();
}

expand_files(){
	files->resize_in_progress = true;
	error = expand_fdtable(files, nr);
	{
		spin_unlock(&files->file_lock);
		if (atomic_read(&files->count) > 1)
			synchronize_rcu();
		spin_lock(&files->file_lock);
	}
	files->resize_in_progress = false;
}
```


----

是否有更一般的设计结构？或者说这是否是一种一般的设计形式？ 

#### 这是一个通用的设计模式吗？

是的，这绝对是操作系统内核乃至高性能并发编程中一种**非常经典且成熟的通用设计模式**。

在并发编程领域，通常把它称为：**“RCU 无锁快通道 + 状态网关标志位 + 加锁慢通道回退（RCU Fast-Path with Control Flag & Slow-Path Fallback）”**。

我们可以把它拆解为这个通用模式的几个核心步骤：

1. **纯 RCU 的局限性：**
标准的、最简单的 RCU 只适合做“指针替换”（比如链表里删个节点、树里换个子指针）。但像文件描述符表（`fdtable`）这种**动态数组**，扩容时需要重新分配内存、拷贝数据，单纯靠换指针是不够的。
2. **控制网关（Control Flag）：**
当写者需要做大动作（扩容）时，它不能直接改，因为会有源源不断的新读者进来。所以它必须先立起一个标志位（如 `resize_in_progress = true`），作为一个“收费站关卡”，拦截后续的新读者。
3. **排空阶段（Draining）：**
通过 `synchronize_rcu()` 等待所有在立起标志位之前就已经进来的“老读者”全部离开（`rcu_read_unlock`）。
4. **慢通道回退（Slow-path Fallback）：**
对于在扩容期间进来的新请求，如果它们盲目自旋等待，效率会极低。因此设计一个**慢通道**（如 `fd_install_slowpath`），让它们老老实实去获取传统的互斥锁（`file_lock`）来完成操作。


#### rwlock vs rcu
there is no native rwlock for cpu. so a rwlock is something that mutex+read state+write state. the read state and write state is the shared data. so

1. read count++ will trigger a lot of lock conflict
2. cpus need sync from memory, instead of just cache
3. in those state that write thing has no big effect to existing ones. reader should not be blocked by writer

these are performance problem that rwlock exist.

#### This is rcu sync read example
for fd_install and expand_table case, as fd_install need the new version of files. it wait for lock, if for some other cases, it just read and continue, and get the old version or new version of data, depending on the sequence of read and update the pointer. so the fd_install and expand_table gives us a sync read example.

as the expand case is very rare, rcu is totally enough

## Wikipedia of rcu
https://en.wikipedia.org/wiki/Read-copy-update

https://gemini.google.com/app/a3253782e7e381dc

### coordination of time and space
In plain English, **coordination** means organizing different parts or people so they **work together smoothly without stepping on each other's toes or causing chaos**. In short: manage to cooperation

1. Coordination in Space (Managing Memory): how different version of structures exist in memory
2. Coordination in Time (Managing the Timeline): how different version of structures re-arrange with time flies
    1. Swap the pointer *now*.
    2. Wait over a period of *time* (the grace period) for old readers to finish.
    3. Free the old memory *later*.

### word definition

* quiescent state: Any statement that is not within an RCU read-side critical section is said to be in a quiescent state.
* grace period: Any time period during which each thread resides at least once in a quiescent state is called a grace period.

 By definition, any RCU read-side critical section in existence at the beginning of a given grace period must complete before the end of that grace period, which constitutes the fundamental guarantee provided by RCU. In addition, the wait-for-readers operation must **wait for at least one grace period to elapse**

## rcu node and tree
When there are a lot of cpus, wait all cpu in quiescent state will take a long time. so we manage them in tree structure, so that reader announce to sub-tree of global tree and writer wait for the sub-tree of global tree 

