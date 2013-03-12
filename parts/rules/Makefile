TARGETS = all build chroot image update-chroot update-local

default:
	@echo "Available targets are:"
	@echo "  ${TARGETS}" | fmt

all: build image

${TARGETS}:
	@./build.sh $@

.PHONY: ${TARGETS}
