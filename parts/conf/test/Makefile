CPPFLAGS = -Wall -Wextra -DDEFAULT_DB_FILEPATH=\"test.db\"
LDFLAGS  = -g -O
CFLAGS   =

.PHONY: all
all: test_libpuavoconf
	@./test_libpuavoconf

test_libpuavoconf.o: test_libpuavoconf.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(shell pkg-config --cflags check) -c $<

test_libpuavoconf: test_libpuavoconf.o ../conf.o
	$(CC) $^ $(LDFLAGS) -ldb $(shell pkg-config --libs check) -o $@

.PHONY: clean
clean:
	rm -f test_libpuavoconf *.o test.db
