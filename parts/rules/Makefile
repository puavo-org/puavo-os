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

.PHONY: deb
deb:
	rm -rf debian
	cp -a debian.default debian
	puavo-dch $(shell cat VERSION)
	dpkg-buildpackage -us -uc
