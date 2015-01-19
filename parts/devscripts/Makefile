prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-dch \
		bin/puavo-install-deps \
		bin/puavo-debuild \
		bin/puavo-build-debian-dir \
		bin/dpkg-diff-img \
		bin/puavo-img-clone \
		bin/puavo-img-chroot \
		bin/puavo-passwd \
		bin/log2db.kdc \
		bin/db2fig.kdc

install-lxc-tools: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-lxc-prepare \
		bin/puavo-lxc-run \
		bin/puavo-lxc-run-sudo-wrap

install-dch-suffix: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/dch-suffix

clean:

clean-deb:
	rm -f ../puavo-devscripts_*.deb
	rm -f ../puavo-devscripts_*.changes
	rm -f ../puavo-devscripts_*.dsc
	rm -f ../puavo-devscripts_*.tar.gz

install-deb-debs:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian.default/control

debiandir:
	rm -rf debian
	cp -a debian.default debian
	puavo-dch $(shell cat VERSION)

deb: debiandir
	dpkg-buildpackage -us -uc

.PHONY : all installdirs install install-lxc-tools install-dch-suffix clean \
	clean-deb debiandir deb
