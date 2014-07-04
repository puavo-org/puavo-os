DESTDIR ?= /opt/cmaptools

%:
	@:

build:
	chmod +x upstream.pack

install:
	sed -r 's|__CMAPTOOLS_INSTALL_DIR__|$(DESTDIR)|' installer.properties >build/installer.properties
	./upstream.pack -f build/installer.properties -i silent || true
