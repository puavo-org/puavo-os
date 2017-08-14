# parts & ports packages go into puavo-os images
_pkgs_parts     := puavo-os
_pkgs_ports     := autopoweroff    \
                   fluentd         \
                   gnome-shell     \
                   grub2           \
                   nwjs            \
                   visionmedia-mon \
                   vtun            \
                   wpa             \
                   $(_lsb_release_ports)
_pkgs_image     := $(_pkgs_parts) $(_pkgs_ports)

# cloud packages do NOT go into puavo-os images
_pkgs_cloud     := krb5 openldap puavo-ds

_dpkg_buildpackage_cloud := $(_pkgs_cloud:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_parts := $(_pkgs_parts:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_ports := $(_pkgs_ports:%=.dpkg-buildpackage-%)
_dpkg_buildpackage       := $(_pkgs_image:%=.dpkg-buildpackage-%)

_install_build_deps_cloud := $(_pkgs_cloud:%=.install-build-deps-%)
_install_build_deps_parts := $(_pkgs_parts:%=.install-build-deps-%)
_install_build_deps_ports := $(_pkgs_ports:%=.install-build-deps-%)
_install_build_deps       := $(_pkgs_image:%=.install-build-deps-%)

_workdir = .workdir

.PHONY: all
all: $(_dpkg_buildpackage)
	$(MAKE) update-repo

.PHONY: cloud
cloud: $(_dpkg_buildpackage_cloud)

.PHONY: parts
parts: $(_dpkg_buildpackage_parts)
	$(MAKE) update-repo

.PHONY: ports
ports: $(_dpkg_buildpackage_ports)
	$(MAKE) update-repo

.PHONY: clean
clean:
	rm -rf .archive $(_workdir)

.dpkg-buildpackage-%: %
	@../.aux/build-debs --build-pkgs "$<" "$(_workdir)" \
	    "$(CURDIR)/.archive/pool"

.PHONY: prepare
prepare: $(_workdir) update-repo

.PHONY: update-repo
update-repo:
	$(MAKE) .archive/Release

$(_workdir):
	mkdir -p $(_workdir)

.archive/Packages: $(wildcard .archive/pool/*.deb)
	mkdir -p .archive/pool
	cd .archive && apt-ftparchive packages pool > Packages

.archive/Packages.gz: .archive/Packages
	gzip -f -k $<

.archive/Release: .archive/Packages.gz
	cd .archive && apt-ftparchive \
	    -o APT::FTPArchive::Release::Origin=puavo-os release . > Release

.PHONY: install-build-deps-cloud
install-build-deps-cloud: $(_install_build_deps_cloud)

.PHONY: install-build-deps-parts
install-build-deps-parts: $(_install_build_deps_parts)

.PHONY: install-build-deps-ports
install-build-deps-ports: $(_install_build_deps_ports)

.PHONY: install-build-deps
install-build-deps: $(_install_build_deps)

.install-build-deps-%: % apt_update
	@env PUAVOOS_SUDO='$(_sudo)' \
	    ../.aux/build-debs --install-build-deps \
	    "$<" "$(_workdir)" "$(CURDIR)/.archive/pool"

.PHONY: apt_update
apt_update:
	$(_sudo) apt-get update
