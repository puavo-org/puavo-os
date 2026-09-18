# syntax=docker/dockerfile:1
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) Opinsys Oy 2026

FROM debian:trixie-slim@sha256:3a39a0592364683e6bab97937b72cad5a8fa6dcbbee90edb3bb48c7f8e94f258

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -o APT::Retries=3 update \
    && apt-get -o APT::Retries=3 install -y --no-install-recommends \
        bash \
        bc \
        binutils \
        bsdiff \
        build-essential \
        bzip2 \
        ca-certificates \
        coreutils \
        cpio \
        curl \
        dbus \
        debianutils \
        debootstrap \
        devscripts \
        diffutils \
        dput \
        efitools \
        file \
        findutils \
        gawk \
        git \
        gnupg \
        gosu \
        grub-common \
        grub2-common \
        gzip \
        locales \
        lsb-release \
        make \
        openssh-client \
        openssl \
        passwd \
        patch \
        perl \
        python3 \
        rsync \
        sbsigntool \
        sed \
        squashfs-tools \
        sudo \
        systemd \
        systemd-boot-efi \
        systemd-ukify \
        python3-cryptography \
        python3-pydantic \
        libtss2-esys-3.0.2-0t64 \
        libtss2-mu-4.0.1-0t64 \
        libtss2-rc0t64 \
        tar \
        unzip \
        util-linux \
        wget \
        xz-utils \
        zstd \
    && case "$(dpkg --print-architecture)" in \
         amd64) apt-get -o APT::Retries=3 install -y --no-install-recommends \
                  grub-efi-amd64-bin grub-efi-ia32-bin ;; \
         *) echo "note: skipping x86_64/i386 GRUB modules" ;; \
       esac \
    && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)$/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# Mark this container as a Puavo OS build host so that the Makefile does
# not attempt to run "setup-buildhost" (which expects systemd) at build
# time.  The build directories themselves are created at runtime, because
# a volume may be mounted over /home.
RUN mkdir -p /etc/puavo \
    && touch /etc/puavo/.is_puavo_buildhost

ENV HOME=/home/puavo-builder \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# debootstrap runs chroot with PATH=/sbin:/usr/sbin:/bin:/usr/bin, so
# the wrapper must shadow the real chroot in /usr/sbin.
RUN mv /usr/sbin/chroot /usr/sbin/chroot.real
COPY --chmod=0755 scripts/chroot /usr/sbin/chroot
COPY --chmod=0755 scripts/build-helper.sh /usr/local/bin/build-helper

WORKDIR /workspace

CMD ["/usr/local/bin/build-helper"]
