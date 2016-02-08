.PHONY: all
all:

.PHONY: installdirs
installdirs:
	$(MAKE) -C rules -f Makefile.install installdirs

.PHONY: install
install: installdirs
	$(MAKE) -C rules -f Makefile.install install

.PHONY: install-build-deps
install-build-deps:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian/control

.PHONY: clean
clean:

.PHONY: deb
deb:
	dpkg-buildpackage -us -uc
