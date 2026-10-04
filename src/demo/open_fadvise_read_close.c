#include <stdio.h>
#include <fcntl.h>
#include <linux/fadvise.h>
#include <unistd.h>
#include <stdlib.h>
int main(int argc, char *argv[]){
	char *file_path = argv[1];
	int read_size = atoi(argv[2]);

	printf("%s %d\n", file_path, read_size);

	int fd = open(file_path, O_RDONLY);
	posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);
	char* buf = (char *)malloc(sizeof(char) * read_size);

	printf("buf: %p\n", buf);
	read_size = read(fd, buf, read_size);
	printf("read size: %d B\n", read_size);
	printf("%s\n", buf);

	free(buf);
	close(fd);
	return 0;
}


