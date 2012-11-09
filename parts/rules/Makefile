TARGETS = all build chroot image update-chroot update-local

default:
	@echo "Available targets are: ${TARGETS}"

all: build image

${TARGETS}:
	@./build.sh $@
