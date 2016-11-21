prefix=/usr/local
bindir=$(prefix)/bin

.PHONY: all
all:

.PHONY: install
install:
	mkdir -p $(DESTDIR)$(bindir)
	install -m 0755 -t $(DESTDIR)$(bindir) \
		bs-release-create \
		bs-release-publish \
		bs-release-rename \
		bs-release-set-latest

.PHONY: clean
clean:
