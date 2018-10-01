#!/bin/sh

set -eu

FILE=mod512
FILE=kuva.jpg
FILE=$1

[ -f $FILE ] && rm $FILE

# dep: sudo apt-get install tftp-hpa
tftp -m octet localhost -c get $FILE

ls -l $FILE tftpboot/$FILE
sha1sum $FILE tftpboot/$FILE
