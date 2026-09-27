#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
int main(int argc, char *argv[]){
	int fd = open(argv[1], O_WRONLY);
	int write_bytes = atoi(argv[2]);
	int i;
	write_bytes=((write_bytes)/4)*4;
	char *buf;
	//buf = malloc(write_bytes);
	//for (i = 0; i < write_bytes; i+=4){
	//	buf[i+0] = 'A';
	//	buf[i+1] = '5';
	//	buf[i+2] = '5';
	//	buf[i+3] = 'A';
	//}
	write(fd, buf, write_bytes);
	fsync(fd);
	printf("bytes: %d\n", write_bytes);
	//printf("%s\n", buf);
	close(fd);
	return 0;
}
