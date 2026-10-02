
在 C 语言中，宏定义中的三个点（...）被称为可变参数宏（Variadic Macros） [1]。它允许你编写能够接受任意数量参数的宏，最常用于封装日志打印函数（如 printf）。
根据你使用的 C 语言标准，主要有以下两种实现方式：

## 1. C99 标准法：使用 `__VA_ARGS__`
在 C99 标准中，宏中的 ... 代表可变参数，在宏的替换列表中使用 __VA_ARGS__ 来接收并替换这些参数。

```c
#include <stdio.h>
// 定义一个调试日志宏
#define LOG_DEBUG(fmt, ...) printf("[DEBUG] " fmt "\n", __VA_ARGS__)
int main() {
    // 替换为:
    printf("[DEBUG] " "Age: %d, Height: %d" "\n", 25, 180);
    LOG_DEBUG("Age: %d, Height: %d", 25, 180); 
    return 0;
}
```

## ⚠️ 潜在的“零参数”编译错误与解决办法
如果调用宏时，... 处没有传任何参数（例如：LOG_DEBUG("Hello")），展开后会变成 printf("[DEBUG] " "Hello" "\n", ) [2]。注意最后多出了一个孤零零的逗号，这会导致编译报错。
为了解决这个问题，不同的标准/编译器提供了以下处理方案：

* C23 标准（推荐现代编译器）：C23 标准引入了 `__VA_OPT__` 机制。

```c
#define LOG_DEBUG(fmt, ...) printf("[DEBUG] " fmt "\n" __VA_OPT__(,) __VA_ARGS__)
// 如果没有可变参数，__VA_OPT__(,) 就会彻底消失，连带删掉逗号 [2]
```

* GCC 编译器扩展（老代码常用）：使用 `##__VA_ARGS__`。

```c
#define LOG_DEBUG(fmt, ...) printf("[DEBUG] " fmt "\n", ##__VA_ARGS__)
// 当可变参数为空时，## 操作符会自动吃掉前面的逗号 [2]
```


------------------------------
## 2. GNU/GCC 扩展法：具名可变参数
在一些老旧的 Linux 内核源码或特定的 GCC 项目中，你可能会看到给三个点起名字的写法（注意：这不是 ANSI C 标准）。

```c
// 给可变参数起名叫 args
#define LOG_INFO(fmt, args...) printf("[INFO] " fmt "\n", ##args)
int main() {
    LOG_INFO("Value: %d", 100);
    return 0;
}
```

------------------------------
您目前是在编写日志系统遇到了编译报错，还是在阅读开源代码（如 Linux 内核）时看到了看不懂的宏？如果能提供您的具体代码片段，我可以帮您精准分析。

