PRECISE_IMAGE_TARGETS = thinclient-precise

TRUSTY_IMAGE_TARGETS = opinsys-trusty           \
		       opinsysextra-trusty      \
		       opinsysrestricted-trusty \
		       puavo-trusty

IMAGE_TARGETS = $(PRECISE_IMAGE_TARGETS) $(TRUSTY_IMAGE_TARGETS)

CHROOT_TARGETS = chroot                        \
                 dist-upgrade                  \
                 image                         \
                 puppet-chroot                 \
                 puppet-chroot-error-on-change \
                 puppet-local                  \
                 update-chroot

OTHER_TARGETS = all help ${CHROOT_TARGETS}

BUILD_DIR = /virtualtmp

help:
	@echo "Available targets are:"
	@echo "  ${OTHER_TARGETS}" | fmt
	@echo
	@echo "Available image types are:"
	@echo "  ${IMAGE_TARGETS}" | fmt

all: ${IMAGE_TARGETS}

${PRECISE_IMAGE_TARGETS}:
	@sudo ./build_puavo_device_image                   \
           --build $(@:%-precise=%) --distribution precise \
           --target-dir ${BUILD_DIR}/$@

${TRUSTY_IMAGE_TARGETS}:
	@sudo ./build_puavo_device_image                 \
           --build $(@:%-trusty=%) --distribution trusty \
           --target-dir ${BUILD_DIR}/$@

chroot dist-upgrade image puppet-chroot puppet-chroot-error-on-change puppet-local update-chroot:
	@TARGET_DIR=$$(./ask_target_dir ${BUILD_DIR}) \
	  && sudo ./build_puavo_device_image --$@ --target-dir $${TARGET_DIR}

.PHONY: ${IMAGE_TARGETS} ${OTHER_TARGETS}
