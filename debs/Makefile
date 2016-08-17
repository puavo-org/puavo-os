_pkgdirs                    := gnome-clocks libpam-envfeed nodejs-bundle node-webkit onboard puavo-os
_install_build_deps_targets := $(_pkgdirs:%=.install-build-deps-%)
_changes_files              := $(foreach _pkgdir,$(_pkgdirs),$(_pkgdir)_$(shell dpkg-parsechangelog -SVersion -l$(_pkgdir)/debian/changelog)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes)

.PHONY: all
all: Packages.gz

.PHONY: clean
clean:
	rm -f db Packages Packages.gz
	rm -rf pool
	git clean -f -d -x -- $(_pkgdirs)
	../parts/devscripts/bin/do-changes -r $(_changes_files)

.PHONY: install-build-deps
install-build-deps: $(_install_build_deps_targets)

Packages: $(_changes_files:%=pool/%)
	apt-ftparchive packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

$(_changes_files):
	./build '$@'

pool/%.changes: %.changes
	../parts/devscripts/bin/do-changes -l pool '$<'

.PHONY: $(_install_build_deps_targets)
$(_install_build_deps_targets): .install-build-deps-%: %
	sudo mk-build-deps -i -r -t					\
		'apt-get --yes --force-yes --no-install-recommends'	\
		'$</debian/control'
