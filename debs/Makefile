_pkgs_stage1 := nodejs-bundle
_pkgs_stage2 := fluentd gnome-clocks libpam-envfeed node-webkit onboard puavo-os
_pkgs        := $(_pkgs_stage1) $(_pkgs_stage2)

_build_deps_stage1 := $(foreach _pkg,$(_pkgs_stage1),$(_pkg)-build-deps_$(shell dpkg-parsechangelog -SVersion -l$(_pkg)/debian/changelog)_all.deb)
_build_deps_stage2 := $(foreach _pkg,$(_pkgs_stage2),$(_pkg)-build-deps_$(shell dpkg-parsechangelog -SVersion -l$(_pkg)/debian/changelog)_all.deb)
_build_deps        := $(_build_deps_stage1) $(_build_deps_stage2)

_install_stamps_build_deps_stage1 := $(_build_deps_stage1:%=.install-stamp-%)
_install_stamps_build_deps_stage2 := $(_build_deps_stage2:%=.install-stamp-%)
_install_stamps_build_deps        := $(_install_stamps_build_deps_stage1) $(_install_stamps_build_deps_stage2)

_changes_files_stage1 := $(foreach _pkg,$(_pkgs_stage1),$(_pkg)_$(shell dpkg-parsechangelog -SVersion -l$(_pkg)/debian/changelog)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes)
_changes_files_stage2 := $(foreach _pkg,$(_pkgs_stage2),$(_pkg)_$(shell dpkg-parsechangelog -SVersion -l$(_pkg)/debian/changelog)_$(shell dpkg-architecture -qDEB_BUILD_ARCH).changes)
_changes_files        := $(_changes_files_stage1) $(_changes_files_stage2)

.PHONY: all
all: stage1 stage2

.PHONY: clean
clean:
	rm -f db Packages Packages.gz
	rm -rf pool
	git clean -f -d -x -- $(_pkgs)
	../parts/devscripts/bin/do-changes -r $(_changes_files)

.PHONY: install-build-deps
install-build-deps: install-build-deps-stage1 install-build-deps-stage2

.PHONY: update-repo
update-repo:
	$(MAKE) Packages.gz

Packages: $(wildcard pool/*.deb)
	mkdir -p pool
	apt-ftparchive packages pool >$@

Packages.gz: Packages
	gzip -f -k $<

$(_changes_files):
	./.aux/build-changes '$@'

pool/%.changes: %.changes
	../parts/devscripts/bin/do-changes -l pool '$<'

.PHONY: stage1
stage1: $(_changes_files_stage1:%=pool/%)
	$(MAKE) update-repo

.PHONY: stage2
stage2: $(_changes_files_stage2:%=pool/%)
	$(MAKE) update-repo

.PHONY: install-build-deps-stage1
install-build-deps-stage1: $(_install_stamps_build_deps_stage1)

.PHONY: install-build-deps-stage2
install-build-deps-stage2: $(_install_stamps_build_deps_stage2)

.install-stamp-%: %
	sudo apt-get update
	sudo dpkg -i '$<'
	sudo apt-get -f -y --force-yes --no-install-recommends install
	touch $@

$(_build_deps):
	./.aux/build-build-deps '$@'
