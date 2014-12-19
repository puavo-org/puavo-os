modules = libnss_puavoadmins.so.0

all: $(modules)

libnss_puavoadmins.so.2: passwd.o
	gcc -shared -o $@ -Wl,-soname,$@ $^

%.o: %.c
	gcc -fPIC -std=c99 -Wpedantic -Wall -Wextra -c $< -o $@

clean:
	rm -rf *.o
	rm -rf $(modules)
