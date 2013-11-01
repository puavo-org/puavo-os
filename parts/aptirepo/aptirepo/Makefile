prefix=/usr/local
exec_prefix=$(prefix)
bindir=$(prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

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
	rm -f $(DESTDIR)$(bindir)/aptirepo-update
	rm -f $(DESTDIR)$(bindir)/aptirepo-init
	rm -f $(DESTDIR)$(bindir)/aptirepo-import

.PHONY: uninstalldirs
uninstalldirs: uninstallfiles
	rmdir --ignore-fail-on-non-empty -p $(DESTDIR)$(bindir)

.PHONY: uninstall
uninstall: uninstalldirs

.PHONY: clean
clean:
