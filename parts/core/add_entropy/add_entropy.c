#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <err.h>
#include <fcntl.h>
#include <linux/random.h>
#include <time.h>
#include <unistd.h>

int
main(void)
{
	size_t i;
	int previous_num, random_fd;
	struct {
		int ent_count;
		int size;
		unsigned char data[1024];
	} entropy;
	struct timespec tp;

	if (clock_gettime(CLOCK_REALTIME, &tp) == -1)
		err(1, "clock_gettime() failed");

	random_fd = open("/dev/random", O_RDWR);
	if (random_fd == -1)
		err(1, "could not open /dev/random");

	entropy.ent_count = 1024;
	entropy.size = 1024;
	previous_num = 1103515245;
	for (i = 0; i < 1024; i++) {
		entropy.data[i] = (previous_num ^ tp.tv_nsec) & 0xff;
		previous_num = (1664525 * previous_num + 1013904223)
				 & 0xffffffff;
	}

	if (ioctl(random_fd, RNDADDENTROPY, &entropy) == -1)
		err(1, "ioctl() RNDADDENTROPY to /dev/random failed");

	(void) close(random_fd);

	return 0;
}
