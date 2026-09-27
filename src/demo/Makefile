# 1. 定义编译器、选项和目录
CC         := gcc
#CFLAGS     := -Wall -Wextra -O2
BUILD_DIR  := build

# 2. 自动获取当前目录下的所有 .c 文件
SRCS       := $(wildcard *.c)

# 3. 将目标文件映射到 build 目录中 (例如: main.c -> build/main)
TARGETS    := $(patsubst %.c, $(BUILD_DIR)/%, $(SRCS))

# 4. 默认目标
all: $(TARGETS) $(BUILD_DIR)/example.txt

# 5. 核心编译规则
# % 匹配文件名，$< 代表输入的 .c 文件，$@ 代表输出的 build/ 路径下的可执行文件
$(BUILD_DIR)/%: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $< -o $@

$(BUILD_DIR)/example.txt: example.sh | $(BUILD_DIR)
	./example.sh > $(BUILD_DIR)/example.txt

# 6. 确保 build 目录存在的“秩序依赖”规则 (Order-only prerequisite)
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# 7. 清理规则
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean
