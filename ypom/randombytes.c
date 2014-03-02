#include <stdio.h>

void randombytes(unsigned char *ptr, unsigned long long length) 
{
	FILE *fh = fopen("/dev/urandom", "rb");
	if (fh != NULL) {
		if (fread(ptr, length, 1, fh) == 0) {
			/* error */
		}
		fclose(fh);
	} else {
		/* error */
	}
}

