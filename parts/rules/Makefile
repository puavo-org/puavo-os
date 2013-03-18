TARGETS = all build chroot image update-chroot update-local

all: build image

help:
	@echo "Available targets are:"
	@echo "  ${TARGETS}" | fmt

${TARGETS}:
	@./build.sh $@

.PHONY: ${TARGETS}
