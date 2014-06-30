IMAGE_TARGETS = opinsys opinsysrestricted puavo thinclient
OTHER_TARGETS = all build-chroot chroot image update-chroot update-local

LOGFILE = $(shell echo logs/ltsp-$$(date +%Y-%m-%d-%H%M%S).log)

help:
	@echo "Available targets are:"
	@echo "  ${OTHER_TARGETS}" | fmt
	@echo
	@echo "Available image types are:"
	@echo "  ${IMAGE_TARGETS}" | fmt

all: ${IMAGE_TARGETS}

${IMAGE_TARGETS}:
	@sudo ./build_puavo_device_image --build-all-for $@ 2>&1 \
	   | tee -a ${LOGFILE}

build-chroot:
	@if [ -z "${IMAGE}" ]; then echo define IMAGE; exit 1; fi
	@sudo ./build_puavo_device_image --$@ ${IMAGE} 2>&1 \
	   | tee -a ${LOGFILE}

image update-chroot update-local:
	@sudo ./build_puavo_device_image --$@ 2>&1 | tee -a ${LOGFILE}

chroot:
	@sudo ./build_puavo_device_image --$@

.PHONY: ${IMAGE_TARGETS} ${TARGETS}
