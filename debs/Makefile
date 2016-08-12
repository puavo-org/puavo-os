subdirs                    := gnome-clocks puavo-os
subdirs-get-orig-source    := $(subdirs:%=.get-orig-source-%)
subdirs-dpkg-buildpackage  := $(subdirs:%=.dpkg-buildpackage-%)
subdirs-install-build-deps := $(subdirs:%=.install-build-deps-%)

.PHONY: all
all: Packages.gz

.PHONY: clean
clean:
	rm -f db Packages Packages.gz
	rm -rf pool

.PHONY: install-build-deps
install-build-deps: $(subdirs-install-build-deps)

Packages: $(subdirs-dpkg-buildpackage)
	apt-ftparchive packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

.PHONY: $(subdirs-dpkg-buildpackage)
$(subdirs-dpkg-buildpackage): .dpkg-buildpackage-%: % .get-orig-source-%
	cd $< && dpkg-buildpackage -b -uc && \
		../../parts/devscripts/bin/cp-changes -l ../pool

.PHONY: $(subdirs-get-orig-source)
$(subdirs-get-orig-source): .get-orig-source-%: %
	cd $< && debian/scripts/get-orig-source

.PHONY: $(subdirs-install-build-deps)
$(subdirs-install-build-deps): .install-build-deps-%: %
	mk-build-deps -i -r -t						\
		'apt-get --yes --force-yes --no-install-recommends'	\
		'$</debian/control'
