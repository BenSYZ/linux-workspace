In the Linux kernel, **`__releases`** and **`__acquires`** are **static analyzer annotations** used by **Sparse** (the kernel's semantic parser/checker tool) to track locking context and states.

They are *not* runtime cleanup mechanisms like `__cleanup` (or `__free`), but rather hints to help the compiler toolchain verify that locks are managed correctly.

---

### What Do They Do?

* **`__acquires(x)`**: Tells Sparse that the function enters with the lock `x` **not held**, but exits with lock `x` **held**.
* **`__releases(x)`**: Tells Sparse that the function enters with the lock `x` **held**, but exits with lock `x` **not held**.

When you see both used together on a single function signature (like in `expand_files`), it usually means the function **drops and re-acquires** a lock midway through its execution (often to avoid holding a spinlock while allocating memory or doing something that might block).

To Sparse, the lock count balances out overall (held in, held out), but because the lock state changes temporarily inside, Sparse would normally throw a **context imbalance warning**. These annotations tell Sparse: *"Trust me, I know this lock is released and re-acquired here."*

---

### Are They Like `__cleanup`?

* **No, not functionally.**
* **`__cleanup`** (introduced via `<linux/cleanup.h>`) is a modern GCC/Clang-based **automatic resource management** feature (using `__attribute__((cleanup(...)))`) that automatically releases a lock or frees memory when a variable goes out of scope.
* **`__releases` / `__acquires**` are **static analysis checks** processed only by Sparse during build-time code checks. For standard GCC/Clang builds, these macros expand to nothing (`__attribute__((context(...)))` is ignored by standard GCC).



---

### Under the Hood

For a Sparse build, they map to GCC context attributes:

* `#define __acquires(x) __attribute__((context(x,0,1)))` (0 contexts in, 1 context out)
* `#define __releases(x) __attribute__((context(x,1,0)))` (1 context in, 0 contexts out)
