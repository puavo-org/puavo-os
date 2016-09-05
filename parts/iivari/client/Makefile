.PHONY: all
all:
	python setup.py build

.PHONY: install
install:
	python setup.py install --install-layout=deb --root=$(DESTDIR)

.PHONY: clean
clean:
	rm -rf build
	find iivari -type f -name '*.pyc' -delete
