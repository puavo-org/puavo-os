prefix=/usr/local
exec_prefix=$(prefix)
bindir=$(prefix)/bin

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
	mkdir -p $(DESTDIR)$(bindir)

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) aptirepo-import
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) aptirepo-init
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) aptirepo-update

.PHONY: uninstallfiles
uninstallfiles:
	rm -f $(DESTDIR)$(bindir)/aptirepo-import
	rm -f $(DESTDIR)$(bindir)/aptirepo-init
	rm -f $(DESTDIR)$(bindir)/aptirepo-update

.PHONY: uninstalldirs
uninstalldirs: uninstallfiles
	rmdir --ignore-fail-on-non-empty -p $(DESTDIR)$(bindir)

.PHONY: uninstall
uninstall: uninstalldirs

.PHONY: clean
clean:
