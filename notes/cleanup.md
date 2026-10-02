
## stack unwind

* call: stack up
* return: stack unwind

https://stackoverflow.com/a/2332865/13033234

概念常位于退出时，释放资源的顺序。xorg 中“no unwind info found” unwind 也是再尝试展开栈


## cleanup attribute
https://wangzhou.github.io/Linux内核cleanup特性/

```c
#include <stdio.h>
void print(int *self){
	printf("destructor(%p): %d\n", self, *self);
}

int main(int argc, char *argv[]){
	int a __attribute__((__cleanup__(print))) = 1; // avoid override by user, just a notation, not insurance
	printf("addr of a=%p\n", &a);
	int b __attribute__((cleanup(print))) = 2;
	b--;
	b--;
	return 0;
}

```

cleanup 传入的是被修饰变量的地址。


## kernel cleanup

```c
#include <stdio.h>
#include <stdlib.h>

#define __cleanup(func)			__attribute__((__cleanup__(func)))

#define DEFINE_CLASS(_name, _type, _exit, _init, _init_args...)		\
typedef _type class_##_name##_t;					\
typedef _type lock_##_name##_t;						\
static __always_inline void class_##_name##_destructor(_type *p)	\
{ _type _T = *p; _exit; }						\
static __always_inline _type class_##_name##_constructor(_init_args)	\
{ _type t = _init; return t; }

#define CLASS(_name, var)						\
	class_##_name##_t var __cleanup(class_##_name##_destructor) =	\
		class_##_name##_constructor

//#define DEFINE_CLASS(_name, _type, _exit, _init, _init_args...)
DEFINE_CLASS(IntPointer, int *, free(_T), malloc(size), unsigned long size);
// _name: IntPointer:           typedef int * IntPointer;
// _exit: free(_T):             free(IntPointer impl);
// _init: malloc(size):         IntPointer impl = malloc(size);
// __init_args


//int *get_int(unsigned long size){
//	int *tmp = (int *)malloc(size);
//	return tmp;
//}
//void put_int(int *p){
//	free(p);
//}
//DEFINE_CLASS(IntPointer, int *, put_int(_T), get_int(size), unsigned long size);

int main(int argc, char *argv[]){
	CLASS(IntPointer, p_var)(sizeof(int));

	printf("%d\n", *p_var);
	
	return 0;
}
```

## EXTEND_CLASS

`EXTEND_CLASS` 的实现是复用 destructor，用新的 construtor。用途是同一个类型的变量，但是来源不同。

```c
DEFINE_CLASS(filename, struct filename *, putname(_T), getname(p), const char __user *p)
EXTEND_CLASS(filename, _kernel, getname_kernel(p), const char *p)
EXTEND_CLASS(filename, _flags, getname_flags(p, f), const char __user *p, unsigned int f)
EXTEND_CLASS(filename, _uflags, getname_uflags(p, f), const char __user *p, unsigned int f)
EXTEND_CLASS(filename, _maybe_null, getname_maybe_null(p, f), const char __user *p, unsigned int f)
EXTEND_CLASS(filename, _complete_delayed, complete_getname(p), struct delayed_filename *p)
```

```c
	CLASS(filename_flags, filename)(path,
			 (flags & FSPICK_EMPTY_PATH) ? LOOKUP_EMPTY : 0);
	ret = filename_lookup(dfd, filename, lookup_flags, &target, NULL);
```

```c
#include <stdio.h>
#include <stdlib.h>

#define __cleanup(func)			__attribute__((__cleanup__(func)))

#define DEFINE_CLASS(_name, _type, _exit, _init, _init_args...)		\
typedef _type class_##_name##_t;					\
typedef _type lock_##_name##_t;						\
static __always_inline void class_##_name##_destructor(_type *p)	\
{ _type _T = *p; _exit; }						\
static __always_inline _type class_##_name##_constructor(_init_args)	\
{ _type t = _init; return t; }

#define CLASS(_name, var)						\
	class_##_name##_t var __cleanup(class_##_name##_destructor) =	\
		class_##_name##_constructor


#define EXTEND_CLASS_COND(_name, ext, _cond, _init, _init_args...)	\
typedef lock_##_name##_t lock_##_name##ext##_t;				\
typedef class_##_name##_t class_##_name##ext##_t;			\
static __always_inline void class_##_name##ext##_destructor(class_##_name##_t *_T) \
{ if (_cond) return; class_##_name##_destructor(_T); }			\
static __always_inline class_##_name##_t class_##_name##ext##_constructor(_init_args) \
{ class_##_name##_t t = _init; return t; }

#define EXTEND_CLASS(_name, ext, _init, _init_args...)			\
	EXTEND_CLASS_COND(_name, ext, 0, _init, _init_args)


//#define DEFINE_CLASS(_name, _type, _exit, _init, _init_args...)
DEFINE_CLASS(IntPointer, int *, free(_T), malloc(size), unsigned long size);
// _name: IntPointer:           typedef int * IntPointer;
// _exit: free(_T):             free(IntPointer impl);
// _init: malloc(size):         IntPointer impl = malloc(size);
// __init_args

int *set_int_with(unsigned long size, int init_val){
	int *tmp = (int *)malloc(size);
	*tmp=init_val;
	return tmp;
}

EXTEND_CLASS(IntPointer, _Init, set_int_with(size, init_val), unsigned long size, int init_val);

int main(int argc, char *argv[]){

	CLASS(IntPointer, p_var)(sizeof(int));
	*p_var=10;
	printf("%d\n", *p_var);

	CLASS(IntPointer_Init, p_var_init)(sizeof(int), 9);
	printf("%d\n", *p_var_init);
	
	return 0;
}

```

## guard

```c
void lock(int *locker){
	(*locker)++;
	printf("lock: ref=%d\n", *locker);
}

void unlock(int *locker){
	(*locker)--;
	printf("unlock: ref=%d\n", *locker);
}

DEFINE_GUARD(Guard, int *, lock(_T), unlock(_T));

int locker;
guard(Guard)(&locker);
```

```c
DEFINE_LOCK_GUARD_1(spinlock, spinlock_t, spin_lock(_T->lock), spin_unlock(_T->lock))
guard(spinlock)(&file->f_lock);
```


```c
// BAD example
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>

#define __cleanup(func)			__attribute__((__cleanup__(func)))

#define DEFINE_CLASS(_name, _type, _exit, _init, _init_args...)		\
typedef _type class_##_name##_t;					\
typedef _type lock_##_name##_t;						\
static __always_inline void class_##_name##_destructor(_type *p)	\
{ _type _T = *p; _exit; }						\
static __always_inline _type class_##_name##_constructor(_init_args)	\
{ _type t = _init; return t; }

#define CLASS(_name, var)						\
	class_##_name##_t var __cleanup(class_##_name##_destructor) =	\
		class_##_name##_constructor


#define EXTEND_CLASS_COND(_name, ext, _cond, _init, _init_args...)	\
typedef lock_##_name##_t lock_##_name##ext##_t;				\
typedef class_##_name##_t class_##_name##ext##_t;			\
static __always_inline void class_##_name##ext##_destructor(class_##_name##_t *_T) \
{ if (_cond) return; class_##_name##_destructor(_T); }			\
static __always_inline class_##_name##_t class_##_name##ext##_constructor(_init_args) \
{ class_##_name##_t t = _init; return t; }

#define EXTEND_CLASS(_name, ext, _init, _init_args...)			\
	EXTEND_CLASS_COND(_name, ext, 0, _init, _init_args)


//#define DEFINE_CLASS(_name, _type, _exit, _init, _init_args...)
DEFINE_CLASS(IntPointer, int *, free(_T), malloc(size), unsigned long size);
// _name: IntPointer:           typedef int * IntPointer;
// _exit: free(_T):             free(IntPointer impl);
// _init: malloc(size):         IntPointer impl = malloc(size);
// __init_args

int *set_int_with(unsigned long size, int init_val){
	int *tmp = (int *)malloc(size);
	*tmp=init_val;
	return tmp;
}
EXTEND_CLASS(IntPointer, _Init, set_int_with(size, init_val), unsigned long size, int init_val);

int IS_ERR(void *ptr){
	return 0;
}
int IS_ERR_VALUE(long int ptr){
	return 0;
}



#define __DEFINE_CLASS_IS_CONDITIONAL(_name, _is_cond)	\
static /*__maybe_unused*/ const bool class_##_name##_is_conditional = _is_cond

#define __DEFINE_GUARD_LOCK_PTR(_name, _exp)                                \
	static __always_inline void *class_##_name##_lock_ptr(class_##_name##_t *_T) \
	{                                                                   \
		void *_ptr = (void *)(/*__force*/ unsigned long)*(_exp);        \
		if (IS_ERR(_ptr)) {                                         \
			_ptr = NULL;                                        \
		}                                                           \
		return _ptr;                                                \
	}                                                                   \
	static __always_inline int class_##_name##_lock_err(class_##_name##_t *_T) \
	{                                                                   \
		long _rc = (/*__force*/ unsigned long)*(_exp);                  \
		if (!_rc) {                                                 \
			_rc = -EBUSY;                                       \
		}                                                           \
		if (!IS_ERR_VALUE(_rc)) {                                   \
			_rc = 0;                                            \
		}                                                           \
		return _rc;                                                 \
	}

#define DEFINE_CLASS_IS_GUARD(_name) \
	__DEFINE_CLASS_IS_CONDITIONAL(_name, false); \
	__DEFINE_GUARD_LOCK_PTR(_name, _T)
#define DEFINE_GUARD(_name, _type, _lock, _unlock) \
	static __always_inline /*__nonnull_args(1)*/ _type class_##_name##_constructor(_type _T); \
	DEFINE_CLASS(_name, _type, _unlock, ({ _lock; _T; }), _type _T); \
	DEFINE_CLASS_IS_GUARD(_name)

#define ___PASTE(a, b) a##b
#define __PASTE(a, b) ___PASTE(a, b)
#define __UNIQUE_ID(name)					\
	__PASTE(__UNIQUE_ID_,					\
	__PASTE(name,						\
	__PASTE(_, __COUNTER__)))
//#define __UNIQUE_ID(x) locker_with_id##__UNIQUE_ID_
#define guard(_name) \
	CLASS(_name, __UNIQUE_ID(guard))

void lock(int *locker){
	(*locker)++;
	printf("lock: ref=%d\n", *locker);
}

void unlock(int *locker){
	(*locker)--;
	printf("unlock: ref=%d\n", *locker);
}

DEFINE_GUARD(Guard, int *, lock(_T), unlock(_T));

int *locker_g;
int main(int argc, char *argv[]){
	locker_g = malloc(sizeof(int));

	CLASS(IntPointer, p_var)(sizeof(int));
	*p_var=10;
	printf("%d\n", *p_var);

	CLASS(IntPointer_Init, p_var_init)(sizeof(int), 9);
	printf("%d\n", *p_var_init);

	int locker;
	guard(Guard)(locker_g);
	guard(Guard)(&locker);

	
	return 0;
}
```

