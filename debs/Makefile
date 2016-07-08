debs                    := $(wildcard pool/*.deb)
subdirs                 := gnome-clocks
get-orig-source-subdirs := $(subdirs:%=get-orig-source-%)
build-subdirs           := $(subdirs:%=build-%)

.PHONY: all
all: Packages.gz

Packages: $(debs)
	apt-ftparchive --db db packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

.PHONY: clean
clean:
	rm -f db Packages Packages.gz

.PHONY: build
build: $(build-subdirs)

.PHONY: $(build-subdirs)
$(build-subdirs): build-%: % get-orig-source-%
	cd $< && dpkg-buildpackage -b -uc && \
		../../parts/devscripts/bin/cp-changes ../pool

.PHONY: $(get-orig-source-subdirs)
$(get-orig-source-subdirs): get-orig-source-%: %
	cd $< && debian/scripts/get-orig-source
