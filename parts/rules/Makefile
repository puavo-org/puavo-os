PRECISE_IMAGE_TARGETS = thinclient-precise

TRUSTY_IMAGE_TARGETS = opinsys-trusty           \
		       opinsysextra-trusty      \
		       opinsysrestricted-trusty \
		       puavo-trusty

IMAGE_TARGETS = $(PRECISE_IMAGE_TARGETS) $(TRUSTY_IMAGE_TARGETS)

CHROOT_TARGETS = chroot                        \
                 cleanup-chroot                \
                 dist-upgrade                  \
                 image                         \
                 puppet-chroot                 \
                 puppet-chroot-error-on-change \
                 puppet-local                  \
                 update-chroot

OTHER_TARGETS = all help ${CHROOT_TARGETS}

help:
	@echo "Available targets are:"
	@echo "  ${OTHER_TARGETS}" | fmt
	@echo
	@echo "Available image types are:"
	@echo "  ${IMAGE_TARGETS}" | fmt

all: ${IMAGE_TARGETS}

${PRECISE_IMAGE_TARGETS}:
	@sudo puavo-build-image --build $(@:%-precise=%) --distribution precise

${TRUSTY_IMAGE_TARGETS}:
	@sudo puavo-build-image --build $(@:%-trusty=%)  --distribution trusty

chroot cleanup-chroot dist-upgrade image puppet-chroot puppet-chroot-error-on-change puppet-local update-chroot:
	sudo puavo-build-image --$@

.PHONY: ${IMAGE_TARGETS} ${OTHER_TARGETS}
