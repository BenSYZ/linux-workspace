#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>

int main() {
    // 1. Open the file
    int fd = open("example.txt", O_RDWR);
    if (fd == -1) {
        perror("Error opening file");
        return 1;
    }

    // 2. Get the size of the file
    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        perror("Error getting file size");
        close(fd);
        return 1;
    }

    // 3. Map the file into memory
    char *file_in_memory = mmap(NULL, sb.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 4096);
    if (file_in_memory == MAP_FAILED) {
        perror("Error mapping file");
        close(fd);
        return 1;
    }

    // 4. Read or write to the file via pointer arithmetic
    printf("First byte of the file: %c\n", file_in_memory[0]);
    file_in_memory[0] = 'z'; // Modifies the file content directly

    // 5. Clean up
    if (munmap(file_in_memory, sb.st_size) == -1) {
        perror("Error unmapping");
    }
    close(fd);
    return 0;
}
