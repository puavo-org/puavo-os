.PHONY: all
all: prepare-tests

.PHONY: prepare-tests
prepare-tests: link-images sync-tests

.PHONY: link-images
link-images:
	# XXX ltsp.img will not boot here.  We should link an installation
	# image, but where could we get one?  Maybe we should prepare one here?
	sudo ln -fns /images/ltsp.img /var/lib/openqa/share/factory/iso/ltsp.img

.PHONY: sync-tests
sync-tests:
	sudo rsync -a --delete --chown=root:root ./ /var/lib/openqa/share/tests/puavo/
