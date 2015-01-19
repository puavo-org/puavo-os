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

.PHONY: debiandir
debiandir:
	rm -rf debian
	cp -a debian.default debian
	puavo-dch $(shell cat VERSION)

.PHONY: deb-binary-arch
deb-binary-arch: debiandir
	dpkg-buildpackage -B -us -uc

.PHONY: deb
deb: debiandir
	dpkg-buildpackage -us -uc
