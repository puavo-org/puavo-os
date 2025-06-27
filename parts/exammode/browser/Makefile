prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all: build

.PHONY: build
build: release/linux-unpacked/puavo-exam-browser

release/linux-unpacked/puavo-exam-browser: package.json
	npm ci
	npm run dist

.PHONY: install
install: build
	mkdir -p $(DESTDIR)/opt/puavo-exam-browser
	cp -RT release/linux-unpacked/ $(DESTDIR)/opt/puavo-exam-browser/
	ln -fns /opt/puavo-exam-browser/puavo-exam-browser \
	    $(DESTDIR)$(bindir)

.PHONY: clean
clean:
	rm -rf dist release node_modules
