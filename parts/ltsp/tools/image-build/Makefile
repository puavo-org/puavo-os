IMAGE_TARGETS = opinsys_desktop
OTHER_TARGETS = all build-chroot chroot image prepare-puppet puppet-chroot

LOGFILE = $(shell echo logs/ltsp-$$(date +%Y-%m-%d-%H%M%S).log)

help:
	@echo "Available targets are:"
	@echo "  ${OTHER_TARGETS}" | fmt
	@echo
	@echo "Available image types are:"
	@echo "  ${IMAGE_TARGETS}" | fmt

all: opinsys_desktop

${IMAGE_TARGETS}:
	@sudo ./build_puavo_device_image --build-all-for image::$@ \
	  2>&1 | tee -a ${LOGFILE}

build-chroot image puppet-chroot:
	@sudo ./build_puavo_device_image --$@ 2>&1 | tee -a ${LOGFILE}

chroot:
	@sudo ./build_puavo_device_image --$@

prepare-puppet:
	@if [ -z "${IMAGE}" ]; then echo define IMAGE; exit 1; fi
	@sudo ./build_puavo_device_image --prepare-puppet image::${IMAGE} \
	  2>&1 | tee -a ${LOGFILE}

.PHONY: ${IMAGE_TARGETS} ${TARGETS}
