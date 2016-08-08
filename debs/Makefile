subdirs                    := gnome-clocks puavo-os
get-orig-source-subdirs    := $(subdirs:%=.get-orig-source-%)
dpkg-buildpackage-subdirs  := $(subdirs:%=.dpkg-buildpackage-%)
install-build-deps-subdirs := $(subdirs:%=.install-build-deps-%)

.PHONY: all
all: Packages.gz

Packages: $(dpkg-buildpackage-subdirs)
	apt-ftparchive --db db packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

.PHONY: clean
clean:
	rm -f db Packages Packages.gz

.PHONY: install-build-deps
install-build-deps: $(install-build-deps-subdirs)

.PHONY: $(dpkg-buildpackage-subdirs)
$(dpkg-buildpackage-subdirs): .dpkg-buildpackage-%: % .get-orig-source-%
	cd $< && dpkg-buildpackage -b -uc && \
		../../parts/devscripts/bin/cp-changes ../pool

.PHONY: $(get-orig-source-subdirs)
$(get-orig-source-subdirs): .get-orig-source-%: %
	cd $< && debian/scripts/get-orig-source

.PHONY: $(install-build-deps-subdirs)
$(install-build-deps-subdirs): .install-build-deps-%: %
	mk-build-deps -i -r -t						\
		'apt-get --yes --force-yes --no-install-recommends'	\
		'$</debian/control'
