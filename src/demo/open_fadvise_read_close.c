#include <stdio.h>
#include <fcntl.h>
#include <linux/fadvise.h>
#include <unistd.h>
#include <stdlib.h>
#define STR_LEN 64
#define BUF_SIZE STR_LEN + 1
int main(int argc, char *argv[]){
	char *file_path = argv[1];
	int read_size = atoi(argv[2]);
	int i;

	printf("%s %d\n", file_path, read_size);

	int fd = open(file_path, O_RDONLY);
	posix_fadvise(fd, 0, 0, POSIX_FADV_DONTNEED);

	char buf[BUF_SIZE];

	printf("buf: %p\n", buf);

	int bytes_read = 0;
	for (i = read_size/STR_LEN + 1 ; i > 0; --i){
		bytes_read = read(fd, buf, STR_LEN);
		if(bytes_read < 0)
			perror("read");
		buf[bytes_read] = '\0';
		printf("%s", buf);
		if(bytes_read == 0)
			break;

	}
	printf("\n");


	close(fd);
	return 0;
}


