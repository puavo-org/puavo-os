# The debian package is created using python-stdeb.

deb: clean
	python setup.py --command-packages=stdeb.command bdist_deb

	@echo "\n *** PACKAGE CONTENTS\n"
	@dpkg-deb -c deb_dist/*.deb
	@echo "\n *** DEBIAN FILES\n"
	@ls -1 deb_dist/iivari-client_*

all:

clean:
	-rm -rf deb_dist
