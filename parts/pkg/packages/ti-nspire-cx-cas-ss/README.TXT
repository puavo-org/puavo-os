#!/bin/sh
#
# How to create the distfile ti-nspire-cx-cas-ss-4.5.0.1180-wineprefix.tar.gz
# ===========================================================================
#
# TI Nspire CX CAS Student Software needs a manual installation under a
# wine environment to work properly.  This installation should be used to
# create the distfile.  Here is a script to do that, but it needs to be
# adjusted for each version and installation environment
# (mostly username "juhaerk" should be changed here).

set -eux

app_version='4.5.0.1180'
target_dir=~/ti-nspire-cx-cas-ss-${app_version}-wineprefix

WINEARCH=win32
WINEPREFIX=~/.wineprefix-ti-nspire-cx-cas

export WINEARCH WINDLLOVERRIDES WINEPREFIX

cd ~

rm -rf "$WINEPREFIX" "$target_dir"

winetricks win7

while pgrep -x wineserver >/dev/null; do
  echo 'waiting for wine'
  sleep 1
done

msiexec /i ~/TINspireCXCASStudentSoftware-${app_version}.msi

while pgrep -x wineserver >/dev/null; do
  echo 'waiting for wine'
  sleep 1
done

rsync -av \
      --exclude 'drive_c/windows/Installer/*.msi' \
      --exclude 'drive_c/users/juhaerk/Omat kuvatiedostot' \
      --exclude 'drive_c/users/juhaerk/Omat musiikkitiedostot' \
      --exclude 'drive_c/users/juhaerk/Omat tiedostot' \
      --exclude 'drive_c/users/juhaerk/Omat videotiedostot' \
      --exclude 'drive_c/users/juhaerk/Start Menu' \
      --exclude 'drive_c/users/juhaerk/Työpöytä' \
       "${WINEPREFIX}/" \
       "${target_dir}/"

mv "${target_dir}/drive_c/users/juhaerk" \
   "${target_dir}/drive_c/users/%%PUAVOUSER%%"

sed -i 's/juhaerk-elitebo/%%PUAVOUSER%%/g' "$target_dir"/*.reg
sed -i 's/juhaerk/%%PUAVOUSER%%/g'         "$target_dir"/*.reg \
       "${target_dir}/drive_c/users/Public/Application Data/TI-Nspire CX CAS/res/INSTALL.LOG"

tar -zcvf ~/ti-nspire-cx-cas-ss-${app_version}-wineprefix.tar.gz \
          ti-nspire-cx-cas-ss-${app_version}-wineprefix

exit 0
