PRECISE_IMAGE_TARGETS = thinclient-precise

TRUSTY_IMAGE_TARGETS = opinsys-trusty           \
		       opinsysextra-trusty      \
		       opinsysrestricted-trusty \
		       puavo-trusty

IMAGE_TARGETS = $(PRECISE_IMAGE_TARGETS) $(TRUSTY_IMAGE_TARGETS)

OTHER_TARGETS = all build-chroot chroot image update-chroot update-local help

help:
	@echo "Available targets are:"
	@echo "  ${OTHER_TARGETS}" | fmt
	@echo
	@echo "Available image types are:"
	@echo "  ${IMAGE_TARGETS}" | fmt

all: ${IMAGE_TARGETS}

${PRECISE_IMAGE_TARGETS}:
	@sudo ./build_puavo_device_image \
           --build-all-for $(@:%-precise=%) --distribution precise

${TRUSTY_IMAGE_TARGETS}:
	@sudo ./build_puavo_device_image \
           --build-all-for $(@:%-trusty=%) --distribution trusty

build-chroot:
	@if [ -z "${IMAGE}" ]; then echo define IMAGE; exit 1; fi
	@sudo ./build_puavo_device_image --$@ ${IMAGE}

image update-chroot update-local:
	@sudo ./build_puavo_device_image --$@

chroot:
	@sudo ./build_puavo_device_image --$@

.PHONY: ${IMAGE_TARGETS} ${OTHER_TARGETS}
