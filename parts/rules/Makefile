TARGETS = all build configure image

default:
	@echo "Available targets are: ${TARGETS}"

all: build image

build configure chroot image:
	./build.sh $@
