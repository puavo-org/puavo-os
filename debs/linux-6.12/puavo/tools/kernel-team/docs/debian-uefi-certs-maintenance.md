# Linux kernel UEFI certs maintenance

Things to remember when updating the Linux kernel in any suite
supporting secure boot and doing UEFI certs maintenance. Current certs
are found in the [code-signing][codes-signing] repository.

[code-signing]: <https://salsa.debian.org/ftp-team/code-signing/-/tree/master/etc> "code-signing etc/"

1. Replace the Debian Secure Boot signer certificate for linux in
   `debian/certs/debian-uefi-certs.pem` and add a respective changelog
   entry like

        certs: Rotate to use the "Debian Secure Boot Signer 2021 - linux" certificate

1. Bump ABI accordingly.
