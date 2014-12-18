modules = libnss_puavoadmins.so.0

all: $(modules)

libnss_puavoadmins.so.0: passwd.o
	gcc -fPIC -shared -o $@ -Wl,-soname,$@ $^

%.o: %.c
	gcc -std=c99 -Wpedantic -Wall -Wextra -c $< -o $@

clean:
	rm -rf *.o
	rm -rf $(modules)
