modules = libnss_puavoadmins.so.2

all: $(modules)

libnss_puavoadmins.so.2: passwd.o
	gcc -shared -o $@ -Wl,-soname,$@ $^

%.o: %.c
	gcc -fPIC -std=c99 -pedantic -Wall -Wextra -c $< -o $@

clean:
	rm -rf *.o
	rm -rf $(modules)
