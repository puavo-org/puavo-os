prefix=/usr/local
libdir=$(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: help
help:
	@echo "Targets:"
	@echo
	@echo "  install    [DESTDIR=''] [prefix='/usr/local']"
	@echo "  uninstall  [DESTDIR=''] [prefix='/usr/local']"

.PHONY: all
all: help

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(libdir)/aptirepo-common

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/aptirepo-common common.sh

.PHONY: uninstallfiles
uninstallfiles:
	rm -f $(DESTDIR)$(libdir)/aptirepo-common common.sh

.PHONY: uninstalldirs
uninstalldirs: uninstallfiles
	rmdir --ignore-fail-on-non-empty -p $(DESTDIR)$(libdir)/aptirepo-common

.PHONY: uninstall
uninstall: uninstalldirs

.PHONY: clean
clean:
