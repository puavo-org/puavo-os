CPPFLAGS = -Wall -Wextra
LDFLAGS  = -g -O
CFLAGS   =

.PHONY: all
all: test_libpuavoconf
	@./test_libpuavoconf

%.o: %.c

test_libpuavoconf.o: test_libpuavoconf.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(shell pkg-config --cflags check dbus-1) -c $<

test_libpuavoconf: test_libpuavoconf.o ../conf.o
	$(CC) $^ $(LDFLAGS) -ldb $(shell pkg-config --libs check dbus-1) -o $@

.PHONY: clean
clean:
	rm -f test_libpuavoconf *.o test.db test.db.lock
