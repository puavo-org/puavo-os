_pkgdirs_stage1 := nodejs-bundle
_pkgdirs_stage2 := gnome-clocks libpam-envfeed node-webkit onboard puavo-os
_pkgdirs        := $(_pkgdirs_stage1) $(_pkgdirs_stage2)

_install_build_deps_targets_stage1 := $(_pkgdirs_stage1:%=.install-build-deps-%)
_install_build_deps_targets_stage2 := $(_pkgdirs_stage2:%=.install-build-deps-%)
_install_build_deps_targets        := $(_install_build_deps_targets_stage1) $(_install_build_deps_targets_stage2)

_changes_files_stage1 := $(foreach _pkgdir,$(_pkgdirs_stage1),$(_pkgdir)_$(shell dpkg-parsechangelog -SVersion -l$(_pkgdir)/debian/changelog)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes)
_changes_files_stage2 := $(foreach _pkgdir,$(_pkgdirs_stage2),$(_pkgdir)_$(shell dpkg-parsechangelog -SVersion -l$(_pkgdir)/debian/changelog)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes)
_changes_files        := $(_changes_files_stage1) $(_changes_files_stage2)

.PHONY: all
all: stage1 stage2

.PHONY: clean
clean:
	rm -f db Packages Packages.gz
	rm -rf pool
	git clean -f -d -x -- $(_pkgdirs)
	../parts/devscripts/bin/do-changes -r $(_changes_files)

.PHONY: install-build-deps
install-build-deps: install-build-deps-stage1 install-build-deps-stage2

.PHONY: update-repo
update-repo: $(_changes_files:%=pool/%)
	$(MAKE) Packages.gz

Packages: $(wildcard pool/*.deb)
	mkdir -p pool
	apt-ftparchive packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

$(_changes_files):
	./build '$@'

pool/%.changes: %.changes
	../parts/devscripts/bin/do-changes -l pool '$<'

.PHONY: stage1
stage1: $(_changes_files_stage1)
	$(MAKE) update-repo

.PHONY: stage2
stage2: $(_changes_files_stage2)
	$(MAKE) update-repo

.PHONY: install-build-deps-stage1
install-build-deps-stage1: $(_install_build_deps_targets_stage1)

.PHONY: install-build-deps-stage2
install-build-deps-stage2: $(_install_build_deps_targets_stage2)

.PHONY: $(_install_build_deps_targets)
$(_install_build_deps_targets): .install-build-deps-%: %
	sudo mk-build-deps -i -r -t					\
		'apt-get --yes --force-yes --no-install-recommends'	\
		'$</debian/control'
