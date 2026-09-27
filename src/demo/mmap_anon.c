#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    long page_size = sysconf(_SC_PAGESIZE);

    // Request a private, anonymous memory page from the kernel
    void *page = mmap(NULL, page_size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

    if (page == MAP_FAILED) {
        perror("mmap failed");
        return 1;
    }

    printf("Kernel allocated page at: %p\n", page);
    fflush(stdout);

    sprintf(page, "Kernel allocated page\n");

    // Free the page back to the kernel
    munmap(page, page_size);
    return 0;
}

