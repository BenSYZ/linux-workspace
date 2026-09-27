//#include <stdio.h>
//#include <unistd.h>
//int main(int argc, char *argv[]){
//	char * page ;
//	page = sbrk(0);
//	printf("%p\n", page);
//	page = sbrk(0);
//	printf("%p\n", page);
//	page = sbrk(1024);
//	printf("%p\n", page);
//	page = sbrk(2048);
//	printf("%p\n", page);
//	return 0;
//}
//

#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

//#define BUF_SIZE 512
//#define printf(...)                                   \
//	do{                                           \
//		char buf[BUF_SIZE] = {0};             \
//		snprintf(buf, BUF_SIZE, __VA_ARGS__); \
//		write(1, buf, BUF_SIZE);              \
//	} while(0);

int main(void) {
	setvbuf(stdout, NULL, _IONBF, 0); 
	// 1. Get the current program break address
	//for (int i = 0; i < BUF_SIZE; i++)
	//	printf("%d", (int)(buf[i]));
	//printf("\n");
	void *initial_break = sbrk(0);
	printf("Initial program break: %p\n", initial_break);

	// 2. Calculate a new break address to allocate 1024 bytes
	size_t bytes_to_allocate = 1024;
	void *new_break = (void *)((uintptr_t)initial_break + bytes_to_allocate);

	// 3. Move the program break to allocate the memory
	// brk() returns 0 on success, and -1 on error
	if (brk(new_break) == -1) {
		perror("brk allocation failed");
		return 1;
	}

	// Verify the break updated successfully
	void *current_break = sbrk(0);
	printf("Program break after allocation: %p\n", current_break);

	// 4. Use the newly allocated memory space safely
	int *array = (int *)initial_break;
	array[0] = 42;
	array[1] = 99;
	printf("Stored values: array[0] = %d, array[1] = %d\n", array[0], array[1]);

	// 5. Deallocate the memory by moving the break back to its original location
	if (brk(initial_break) == -1) {
		perror("brk deallocation failed");
		return 1;
	}

	printf("Program break restored to: %p\n", sbrk(0));
	//sprintf(buf, "Program break restored to: %p\n", sbrk(0));
	//write(1, buf, BUF_SIZE);
	return 0;
}
