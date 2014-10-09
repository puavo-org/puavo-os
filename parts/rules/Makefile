prefix = /usr/local
datarootdir = $(prefix)/share

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-rules/puppet

.PHONY: install
install: installdirs
	cp -R -t $(DESTDIR)$(datarootdir)/puavo-rules/puppet puppet/*

.PHONY: clean
clean:

.PHONY: deb
deb:
	rm -rf debian
	cp -a debian.default debian
	puavo-dch $(shell cat VERSION)
	dpkg-buildpackage -us -uc
