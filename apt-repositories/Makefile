prefix=/usr/local
bindir=$(prefix)/bin

.PHONY: all
all:

.PHONY: install
install:
	mkdir -p $(DESTDIR)$(bindir)
	install -m 0755 -t $(DESTDIR)$(bindir) \
		bs-release

.PHONY: clean
clean:
