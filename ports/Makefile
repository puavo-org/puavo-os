subdirs                    := $(sort $(shell \
	find . -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%f\n'))
get-orig-source-subdirs    := $(subdirs:%=get-orig-source-%)
build-subdirs              := $(subdirs:%=build-%)
install-build-deps-subdirs := $(subdirs:%=install-build-deps-%)

.PHONY: all
all:

.PHONY: clean
clean:

.PHONY: get-orig-source
get-orig-source: $(get-orig-source-subdirs)

.PHONY: build
build: $(build-subdirs)

.PHONY: install-build-deps
install-build-deps: $(install-build-deps-subdirs)

.PHONY: $(get-orig-source-subdirs)
$(get-orig-source-subdirs): get-orig-source-%: %
	cd $< && debian/scripts/get-orig-source

.PHONY: $(build-subdirs)
$(build-subdirs): build-%: % get-orig-source-%
	cd $< \
		&& dpkg-buildpackage -b -uc \
		&& ../../parts/devscripts/bin/cp-changes ../../debs

.PHONY: $(install-build-deps-subdirs)
$(install-build-deps-subdirs): install-build-deps-%: %
	cd $< && mk-build-deps -i -r -t "apt-get --yes --force-yes" \
		debian/control
