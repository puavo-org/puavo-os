prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all:

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)$(bindir)

.PHONY: install
install: install-dirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-webwindow

.PHONY: clean
clean:
