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
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) aptirepo-upload

.PHONY: uninstallfiles
uninstallfiles:
	rm -f $(DESTDIR)$(bindir)/aptirepo-upload

.PHONY: uninstalldirs
uninstalldirs: uninstallfiles
	rmdir --ignore-fail-on-non-empty -p $(DESTDIR)$(bindir)

.PHONY: uninstall
uninstall: uninstalldirs

.PHONY: clean
clean:
