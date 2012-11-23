TARGETS = all build chroot force-reserve free image reserve update-chroot update-local

default:
	@echo "Available targets are:"
	@echo "  ${TARGETS}" | fmt

all: build image

${TARGETS}:
	@./build.sh $@
