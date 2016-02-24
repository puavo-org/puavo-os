.PHONY: all
all:

.PHONY: installdirs
installdirs:
	$(MAKE) -C rules -f Makefile.install installdirs

.PHONY: install
install: installdirs
	$(MAKE) -C rules -f Makefile.install install

.PHONY: clean
clean:
