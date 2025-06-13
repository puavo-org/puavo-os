prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all: build

.PHONY: build
build:
	npm ci
	npm run dist

.PHONY: install
install: build
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-exam-browser
	$(INSTALL_PROGRAM) release/puavo-exam-browser-*.AppImage $(DESTDIR)$(libdir)/puavo-exam-browser/puavo-exam-browser.AppImage
	echo '#!/bin/bash' > $(DESTDIR)$(bindir)/puavo-exam-browser
	echo 'exec $(libdir)/puavo-exam-browser/puavo-exam-browser.AppImage "$$@"' >> $(DESTDIR)$(bindir)/puavo-exam-browser
	chmod +x $(DESTDIR)$(bindir)/puavo-exam-browser

.PHONY: clean
clean:
	rm -rf dist release node_modules
