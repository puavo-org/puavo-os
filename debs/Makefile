# a newer version of unicode-data is a dependency for wine
_pkgs_builddeps := unicode-data

# parts & ports packages go into puavo-os images

_pkgs_parts     := puavo-os
_pkgs_ports     := autopoweroff    \
                   fluentd         \
                   gnome-shell     \
                   grub2           \
                   gvfs            \
                   linux           \
                   mutter          \
                   nwjs            \
                   openboard       \
                   visionmedia-mon \
                   vtun            \
                   wine            \
                   wpa
_pkgs_image     := $(_pkgs_builddeps) $(_pkgs_parts) $(_pkgs_ports)

# cloud packages do NOT go into puavo-os images
_pkgs_cloud     := krb5 openldap puavo-ds

_dpkg_buildpackage_builddeps := $(_pkgs_builddeps:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_cloud     := $(_pkgs_cloud:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_parts     := $(_pkgs_parts:%=.dpkg-buildpackage-%)
_dpkg_buildpackage_ports     := $(_pkgs_ports:%=.dpkg-buildpackage-%)
_dpkg_buildpackage           := $(_pkgs_image:%=.dpkg-buildpackage-%)

_workdir = .workdir

.PHONY: all
all: $(_dpkg_buildpackage)

.PHONY: builddeps
builddeps: $(_dpkg_buildpackage_builddeps)

.PHONY: cloud
cloud: $(_dpkg_buildpackage_cloud)

.PHONY: parts
parts: $(_dpkg_buildpackage_parts)

.PHONY: ports
ports: $(_dpkg_buildpackage_ports)

.PHONY: clean
clean:
	rm -rf .archive $(_workdir)

.dpkg-buildpackage-%: % apt_update
	@env PUAVOOS_SUDO='$(_sudo)' \
	    ../.aux/build-debs "$<" "$(_workdir)" "$(CURDIR)/.archive/pool"
	$(MAKE) update-repo

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
	    -o APT::FTPArchive::Release::Origin=puavo-os-local release . \
	    > Release

.PHONY: apt_update
apt_update:
	$(_sudo) apt-get update
