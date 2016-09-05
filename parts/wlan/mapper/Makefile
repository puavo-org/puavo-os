prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all: horst puavowlanmapper/icons.py
	python setup.py build

horst:
	make -C horst
	cp horst/horst puavo-wlanmapper-horst

puavowlanmapper/icons.py: icons.qrc icons/*.png
	pyrcc4 -py3 $< -o $@

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

install: horst installdirs puavowlanmapper/icons.py
	python3 setup.py install --install-layout=deb --root=$(DESTDIR)
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanmapper-horst

clean:
	make -C horst clean
	rm -f puavo-wlanmapper-horst puavowlanmapper/icons.py
	rm -rf build

.PHONY: all	    \
	clean	    \
	horst	    \
	install	    \
	installdirs
