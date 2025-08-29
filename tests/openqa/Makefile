.PHONY: all
all: sync-tests

sync-tests:
	sudo rsync -a --delete --chown=root:root ./ /var/lib/openqa/share/tests/puavo/
