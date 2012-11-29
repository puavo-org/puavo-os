#!/bin/sh

set -eu

FILE=kuva.jpg

[ -f $FILE ] && rm $FILE

# dep: sudo apt-get install tftp-hpa
tftp -m octet localhost -c get $FILE

ls -l $FILE tftpboot/$FILE
sha1sum $FILE tftpboot/$FILE
