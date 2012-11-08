TARGETS = all build configure chroot image

default:
	@echo "Available targets are: ${TARGETS}"

all: build image

${TARGETS}:
	@./build.sh $@
