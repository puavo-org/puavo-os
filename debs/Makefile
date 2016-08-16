subdirs                    := gnome-clocks libpam-envfeed onboard puavo-os
subdirs-install-build-deps := $(subdirs:%=.install-build-deps-%)
changes_files              := $(foreach subdir,$(subdirs),$(subdir)_$(shell dpkg-parsechangelog -SVersion -l$(subdir)/debian/changelog)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes)

.PHONY: all
all: Packages.gz

.PHONY: clean
clean:
	rm -f db Packages Packages.gz
	rm -rf pool
	git clean -f -d -x -- $(subdirs)
	../parts/devscripts/bin/do-changes -r $(changes_files)

.PHONY: install-build-deps
install-build-deps: $(subdirs-install-build-deps)

Packages: $(changes_files:%=pool/%)
	apt-ftparchive packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

$(changes_files):
	./build '$@'

pool/%.changes: %.changes
	../parts/devscripts/bin/do-changes -l pool '$<'

.PHONY: $(subdirs-install-build-deps)
$(subdirs-install-build-deps): .install-build-deps-%: %
	mk-build-deps -i -r -t						\
		'apt-get --yes --force-yes --no-install-recommends'	\
		'$</debian/control'
