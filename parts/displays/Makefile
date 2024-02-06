prefix=/usr/local
bindir=$(prefix)/bin
libdir=$(prefix)/lib
pylibdir=$(prefix)/lib/python3/dist-packages
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

mypy_targets := puavo-display-manager
pylint_targets := puavo-display-manager puavodisplays

check_mypy_targets := $(mypy_targets:%=check-mypy-%)
check_pylint_targets := $(pylint_targets:%=check-pylint-%)

.PHONY: all
all: check test

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-displays
	mkdir -p $(DESTDIR)/lib/udev/rules.d
	mkdir -p $(DESTDIR)$(pylibdir)/puavodisplays
	mkdir -p $(DESTDIR)$(sysconfdir)/systemd/system/systemd-udevd.service.d

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t '$(DESTDIR)$(bindir)'	\
		puavo-display-manager

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-displays \
		lib/*

	$(INSTALL_DATA) -t $(DESTDIR)/lib/udev/rules.d \
		udev/rules.d/95-monitor-hotplug.rules

	$(INSTALL_DATA) -t '$(DESTDIR)$(pylibdir)/puavodisplays'	\
		puavodisplays/*.py

	$(INSTALL_DATA) -t '$(DESTDIR)$(sysconfdir)/systemd/system/systemd-udevd.service.d' \
		etc/systemd/system/systemd-udevd.service.d/puavo-displays.conf

.PHONY: clean
clean:

.PHONY: $(check_mypy_targets)
$(check_mypy_targets): check-mypy-%: %
	mypy --strict $<

.PHONY:
check-mypy: $(check_mypy_targets)

.PHONY: $(check_pylint_targets)
$(check_pylint_targets): check-pylint-%: %
	pylint $<

.PHONY:
check-pylint: $(check_pylint_targets)

.PHONY: check
check: check-mypy check-pylint

.PHONY: test
test:
	cd tests && pytest -rA -vvv
