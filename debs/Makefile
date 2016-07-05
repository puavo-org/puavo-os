debs := $(wildcard *.deb)

.PHONY: all
all: Packages.gz

Packages: $(debs)
	apt-ftparchive --db db packages . >$@

Packages.gz: Packages
	gzip -f -k $<

.PHONY: clean
clean:
	rm -f db Packages Packages.gz
