# Public, configurable variables
debootstrap_mirror	:= http://httpredir.debian.org/debian/
debootstrap_suite	:= stretch
image_class		:= allinone
image_dir		:= /srv/puavo-os-images
images_urlbase		:= https://images.puavo.org
mirror_dir		:= $(image_dir)/mirror
rootfs_dir		:= /var/tmp/puavo-os/rootfs

include .opinsys/defaults.mk

_adm_user	:= puavo-os
_adm_group	:= puavo-os
_adm_uid	:= 1000
_adm_gid	:= 1000

_repo_name   := $(shell basename $(shell git rev-parse --show-toplevel))
_image_file  := $(image_dir)/$(_repo_name)-$(image_class)-$(debootstrap_suite)-$(shell date -u +%Y-%m-%d-%H%M%S)-amd64.img

# Some basic dependencies for our build system.  "python3" is on this list,
# because installing "devscripts" fails if "python3" has not been installed
# earlier, working around some bug in Debian (on 2016-11-18).
_debootstrap_packages := python3,devscripts,equivs,git,jq,locales,lsb-release,\
			 make,puppet-common,sudo

_cache_configured := $(shell grep -qs puavo-os /etc/squid/squid.conf \
			 && echo true || echo false)
ifdef PUAVO_CACHE_PROXY
  _proxy_address := ${PUAVO_CACHE_PROXY}
else ifeq ($(_cache_configured),true)
  _proxy_address := localhost:3128
endif
ifdef _proxy_address
_proxywrap_cmd := .aux/proxywrap --with-proxy $(_proxy_address)
else
_proxywrap_cmd := .aux/proxywrap
endif

_puppet_apply_cmd := env LC_CTYPE=en_US.UTF-8 puppet apply      \
                       --logdest '/var/log/puavo-os/puppet.log' \
                       --logdest console                        \
                       --modulepath 'rules'                     \
                       rules/site.pp

_systemd_nspawn_machine_name := \
  $(notdir $(rootfs_dir))-$(shell tr -dc A-Za-z0-9 < /dev/urandom | head -c8)
_systemd_nspawn_cmd := sudo systemd-nspawn -D '$(rootfs_dir)' \
			 -M '$(_systemd_nspawn_machine_name)' \
			 -u '$(_adm_user)'                    \
			 --setenv="PUAVO_CACHE_PROXY=$(_proxy_address)"

_sudo := sudo $(_proxywrap_cmd)

.PHONY: build
build: build-debs-ports build-debs-parts

.PHONY: build-debs-parts
build-debs-parts:
	$(MAKE) -C debs parts

.PHONY: build-debs-ports
build-debs-ports:
	$(MAKE) -C debs ports

.PHONY: build-parts
build-parts:
	$(MAKE) -C parts

.PHONY: install
install: install-parts
	$(MAKE) install-rules

.PHONY: install-parts
install-parts: /puavo-os
	$(_sudo) $(MAKE) -C parts install prefix=/usr sysconfdir=/etc

.PHONY: install-build-deps
install-build-deps: /puavo-os
	$(MAKE) -C debs update-repo

	$(_sudo) env FACTER_puavoruleset=prepare $(_puppet_apply_cmd)

	$(_sudo) $(MAKE) -C debs install-build-deps

.PHONY: help
help:
	@echo 'Puavo OS Build System'
	@echo
	@echo 'Targets:'
	@echo '    [build]              build all'
	@echo '    build-debs-parts     build Puavo OS Debian packages'
	@echo '    build-debs-ports     build all external Debian packages'
	@echo '    build-parts          build all parts'
	@echo '    help                 display this help and exit'
	@echo '    install              install all'
	@echo '    install-build-deps   install all build dependencies'
	@echo '    install-parts        install all parts'
	@echo '    install-rules        install all Puppet rules'
	@echo '    rdiffs               make rdiffs for images (uses "rdiff_targets"-variable)'
	@echo '    rootfs-debootstrap   build Puavo OS rootfs from scratch'
	@echo '    rootfs-image         pack rootfs to a squashfs image'
	@echo '    rootfs-shell         spawn shell from Puavo OS rootfs'
	@echo '    rootfs-sync-repo     sync Puavo OS rootfs repo with the current repo'
	@echo '    rootfs-update        update Puavo OS rootfs'
	@echo '    setup-buildhost      some optional setup for buildhost'
	@echo '    update               update Puavo OS localhost'
	@echo
	@echo 'Variables:'
	@echo '    debootstrap_mirror   debootstrap mirror [$(debootstrap_mirror)]'
	@echo '    image_dir            directory where images are built [$(image_dir)]'
	@echo '    images_urlbase       Prefix for image urls (https://...)'
	@echo '    mirror_dir           Mirror directory (for images and rdiffs)'
	@echo '    rootfs_dir           Puavo OS rootfs directory [$(rootfs_dir)]'

$(rootfs_dir):
	@echo ERROR: rootfs does not exist, make rootfs-debootstrap first >&2
	@false

.PHONY: rootfs-debootstrap
rootfs-debootstrap:
	@[ ! -e '$(rootfs_dir)' ] || \
		{ echo ERROR: rootfs directory '$(rootfs_dir)' already exists >&2; false; }
	$(_sudo) debootstrap					\
		--arch=amd64					\
		--include='$(_debootstrap_packages)'	        \
		--components=main,contrib,non-free		\
		'$(debootstrap_suite)'				\
		'$(rootfs_dir).tmp' '$(debootstrap_mirror)'

	$(_sudo) git clone . '$(rootfs_dir).tmp/puavo-os'

	$(_sudo) ln -s '/puavo-os/.aux/policy-rc.d' \
		'$(rootfs_dir).tmp/usr/sbin/policy-rc.d'

	$(_sudo) mv '$(rootfs_dir).tmp' '$(rootfs_dir)'

$(image_dir):
	$(_sudo) mkdir -p '$(image_dir)'

.PHONY: make-release-logos
make-release-logos:
	$(_sudo) /usr/lib/puavo-ltsp-client/make-release-logos

.PHONY: rootfs-image
rootfs-image: $(rootfs_dir) $(image_dir)
	$(_sudo) .aux/set-image-release '$(rootfs_dir)' '$(image_class)' \
	    '$(notdir $(_image_file))'
	$(_systemd_nspawn_cmd) $(MAKE) -C '/puavo-os' make-release-logos
	$(_sudo) mksquashfs '$(rootfs_dir)' '$(_image_file).tmp'	\
		-noappend -no-recovery -wildcards		\
		-ef '.aux/$(image_class).excludes'		\
		|| { rm -f '$(_image_file).tmp'; false; }
	$(_sudo) mv '$(_image_file).tmp' '$(_image_file)'
	@echo Built '$(_image_file)' successfully.

.PHONY: rootfs-shell
rootfs-shell: $(rootfs_dir)
	$(_systemd_nspawn_cmd) '/puavo-os/.aux/proxywrap' \
	   sh -c 'cd ~ && exec bash'

.PHONY: rootfs-sync-repo
rootfs-sync-repo: $(rootfs_dir)
	$(_sudo) .aux/create-adm-user '$(rootfs_dir)' '/puavo-os' \
	    '$(_adm_user)' '$(_adm_group)' '$(_adm_uid)' '$(_adm_gid)'
	$(_sudo) rsync "--chown=$(_adm_uid):$(_adm_gid)" --chmod=Dg+s,ug+w \
	    -glopr . '$(rootfs_dir)/puavo-os/'

.PHONY: rootfs-update
rootfs-update: rootfs-sync-repo
	$(_systemd_nspawn_cmd) $(MAKE) -C '/puavo-os' update

.PHONY: setup-buildhost
setup-buildhost:
	.aux/setup-buildhost

/etc/puavo-conf/image.json: config.json
	$(_sudo) mkdir -p $(@D)
	$(_sudo) sh -c 'jq .puavo_conf config.json > $@.tmp'
	$(_sudo) mv $@.tmp $@

.PHONY: update
update: /etc/puavo-conf/image.json install-build-deps
	$(MAKE)

	$(_sudo) apt-get update
	$(_sudo) apt-get dist-upgrade -V -y			\
		-o Dpkg::Options::="--force-confdef"	\
		-o Dpkg::Options::="--force-confold"

	$(MAKE) install

	$(_sudo) update-initramfs -u -k all
	$(_sudo) updatedb

.PHONY: install-rules
install-rules: /puavo-os
	$(_sudo) .aux/setup-debconf
	$(_sudo) env 'FACTER_puavoruleset=$(image_class)' $(_puppet_apply_cmd)

.PHONY: rdiffs
rdiffs: $(image_dir) $(mirror_dir)
	$(_sudo) .aux/make-rdiffs image_dir="$(image_dir)" \
		images_urlbase="$(images_urlbase)" \
		mirror_dir="$(mirror_dir)" $(rdiff_targets)

$(mirror_dir):
	$(_sudo) mkdir -p '$(mirror_dir)'

/puavo-os:
	@echo ERROR: localhost is not Puavo OS system >&2
	@false
