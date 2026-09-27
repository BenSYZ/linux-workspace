#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
int main(int argc, char *argv[]){
	int fd = open(argv[1], O_RDONLY);
	char buf[512];
	printf("%p:\n", buf);
	read(fd, &buf, atoi(argv[2]));
	printf("%s\n", buf);
	close(fd);
	return 0;
}

