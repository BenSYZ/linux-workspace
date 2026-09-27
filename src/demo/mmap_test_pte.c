#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>

#include <string.h>

int main(int argc, char *argv[]){
    long page_size = sysconf(_SC_PAGESIZE);

    // Request a private, anonymous memory page from the kernel
    void *page = mmap(NULL, 25710*page_size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

    if (page == MAP_FAILED) {
        perror("mmap failed");
        return 1;
    }

    printf("Kernel allocated page at: %p\n", page);
    fsync(1);

    memset(page, 0, 25710*page_size);
    sleep(600);

    //int fd = open(argv[1], O_RDONLY);
    //read(fd, page, atoi(argv[2]));
    //printf("%s\n", (char *)page);
    //close(fd);
    return 0;


    sprintf(page, "Kernel allocated page\n");

    // Free the page back to the kernel
    munmap(page, page_size);
    return 0;
}

