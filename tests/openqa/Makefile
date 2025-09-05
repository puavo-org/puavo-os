OPENQA_ISO_DIR := /var/lib/openqa/share/factory/iso/

.PHONY: all
all: prepare-tests

.PHONY: prepare-tests
prepare-tests: link-images sync-tests

.PHONY: link-images
link-images:
	sudo ../../.aux/create-installer-images
	sudo find /srv/puavo-os-images/install-images -type f -name '*.img' -exec ln -fns \{} "$(OPENQA_ISO_DIR)" \;
	sudo find "$(OPENQA_ISO_DIR)" -type l -name '*.img' ! -exec test -e {} \; -delete

.PHONY: sync-tests
sync-tests:
	sudo rsync -a --delete --chown=root:root ./ /var/lib/openqa/share/tests/puavo/
	sudo chown geekotest: /var/lib/openqa/share/tests/puavo/needles/
