prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

BIN = release/linux-unpacked/puavo-exam-browser
SOURCE_FILES = $(shell find src -type f -name '*')

.PHONY: all
all: build

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)/opt/puavo-exam-browser

.PHONY: build
build: $(BIN)

$(BIN): package.json package-lock.json $(SOURCE_FILES)
	npm ci
	npm run pack

.PHONY: install
install: build installdirs
	cp -RT release/linux-unpacked/ $(DESTDIR)/opt/puavo-exam-browser/
	ln -fns /opt/puavo-exam-browser/puavo-exam-browser \
	    $(DESTDIR)$(bindir)

.PHONY: clean
clean:
	rm -rf dist release node_modules
