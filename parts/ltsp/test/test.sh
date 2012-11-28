#!/bin/sh

set -e

[ -f kuva.jpg ] && rm kuva.jpg

# tftp-hpa client
tftp -m octet localhost -c get kuva.jpg


ls -l kuva.jpg tftpboot/kuva.jpg
sha1sum kuva.jpg tftpboot/kuva.jpg
