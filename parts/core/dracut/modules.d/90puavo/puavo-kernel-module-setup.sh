#!/bin/sh

# Todo: Duplicated
for x in $(cat /proc/cmdline); do
    if [ "$x" = "init=/sbin/init-puavo" ]; then
        BOOT=puavo
        break
    fi
done

if [ "$BOOT" != "puavo" ]; then
  exit 0
fi

# Make sure the initrd filesystem is private instead of shared 
# as moving mounts (see puavo-postmount) within shared mount is not supported
mount --make-private /

mkdir -p /run/puavo

puavo_boot_plymouth_theme=''
puavo_graphics_driver=''
puavo_kernel_modules_blacklist=''
puavo_pm_display_drrs_enabled=''
puavo_wireless_broadcom_driver=''

exec > /run/puavo/initrd.log 2>&1

# check out special puavo.* kernel command line options
# that need (may need?) actions on the initrd-phase
for x in $(cat /proc/cmdline); do
    case "$x" in
        puavo.boot.plymouth.theme=*)
            puavo_boot_plymouth_theme="${x#puavo.boot.plymouth.theme=}"
            ;;
        puavo.graphics.driver=*)
            puavo_graphics_driver="${x#puavo.graphics.driver=}"
            ;;
        puavo.kernel.modules.blacklist=*)
            puavo_kernel_modules_blacklist="${x#puavo.kernel.modules.blacklist=}"
            ;;
        puavo.pm.display.drrs.enabled=*)
            puavo_pm_display_drrs_enabled="${x#puavo.pm.display.drrs.enabled=}"
            ;;
        puavo.wireless.broadcom.driver=*)
            puavo_wireless_broadcom_driver="${x#puavo.wireless.broadcom.driver=}"
            ;;
    esac
done

puavo_nvidia_driver=
case "$puavo_graphics_driver" in
  nvidia)
    puavo_nvidia_driver=current
    ;;
  nvidia-390)
    puavo_nvidia_driver=legacy-390xx
    ;;
esac

if [ -n "$puavo_nvidia_driver" ]; then
  puavo_nvidia_dir="/etc/nvidia/${puavo_nvidia_driver}"

  if [ -e "${puavo_nvidia_dir}/nvidia-blacklists-nouveau.conf" ]; then
    echo "copying ${puavo_nvidia_dir}/nvidia-blacklists-nouveau.conf to" \
         "/etc/modprobe.d/nvidia-blacklists-nouveau.conf"
    cp "${puavo_nvidia_dir}/nvidia-blacklists-nouveau.conf" \
       /etc/modprobe.d/nvidia-blacklists-nouveau.conf
  elif [ -e /etc/nvidia/nvidia-blacklists-nouveau.conf ]; then
    echo "copying /etc/nvidia/nvidia-blacklists-nouveau.conf to" \
         "/etc/modprobe.d/nvidia-blacklists-nouveau.conf"
    cp /etc/nvidia/nvidia-blacklists-nouveau.conf \
       /etc/modprobe.d/nvidia-blacklists-nouveau.conf
  else
    echo 'ERROR: should blacklist nouveau,' \
         "but ${puavo_nvidia_dir}/nvidia-blacklists-nouveau.conf is missing"
  fi

  if [ -e "${puavo_nvidia_dir}/nvidia-modprobe.conf" ]; then
    echo "copying ${puavo_nvidia_dir}/nvidia-modprobe.conf to" \
         "/etc/modprobe.d/nvidia.conf"
    cp "${puavo_nvidia_dir}/nvidia-modprobe.conf" \
       /etc/modprobe.d/nvidia.conf
  elif [ -e "/etc/nvidia/nvidia-modprobe.conf" ]; then
    echo "copying /etc/nvidia/nvidia-modprobe.conf to" \
         "/etc/modprobe.d/nvidia.conf"
    cp /etc/nvidia/nvidia-modprobe.conf /etc/modprobe.d/nvidia.conf
  else
    echo 'ERROR: should use nvidia,' \
         "but ${puavo_nvidia_dir}/nvidia-modprobe.conf is missing"
  fi
else
  echo "removing /etc/modprobe.d/nvidia-blacklists-nouveau.conf and" \
       "/etc/modprobe.d/nvidia.conf if they exist"
  rm -fv /etc/modprobe.d/nvidia-blacklists-nouveau.conf \
         /etc/modprobe.d/nvidia.conf
fi

# Set kernel module blacklists.
# This is similar to /etc/puavo-conf/scripts/manage_module_blacklist.
r8169_blacklisted=false
if [ -n "$puavo_kernel_modules_blacklist" ]; then
  OLDIFS="$IFS"
  IFS=','
  for module in $puavo_kernel_modules_blacklist; do
    echo "blacklist $module" >> /etc/modprobe.d/blacklist-by-puavo-conf.conf
    if [ "$module" = 'r8169' ]; then
      r8169_blacklisted=true
    fi
  done
  IFS="$OLDIFS"
fi

if [ "$puavo_pm_display_drrs_enabled" = 'false' ]; then
  echo 'applying enable_drrs=0 option to i915-module'
  echo 'options i915 enable_drrs=0' > /etc/modprobe.d/i915_disable_drrs.conf
fi

# duplicate code with /etc/puavo-conf/scripts/manage_module_blacklist
case "$puavo_wireless_broadcom_driver" in
  b43)       blacklist_broadcom_modules='    b43legacy b44 brcmsmac wl' ;;
  b43legacy) blacklist_broadcom_modules='b43           b44 brcmsmac wl' ;;
  b44)       blacklist_broadcom_modules='b43 b43legacy     brcmsmac wl' ;;
  brcm80211) blacklist_broadcom_modules='b43 b43legacy b44          wl' ;;
  wl)        blacklist_broadcom_modules='b43 b43legacy b44 bcma brcm80211 brcmsmac ssb' ;;
  *)         blacklist_broadcom_modules='' ;;
esac
for broadcom_module in $blacklist_broadcom_modules; do
  echo "blacklist $broadcom_module"
done > /etc/modprobe.d/broadcom-sta-dkms.conf

if [ -n "$puavo_boot_plymouth_theme" ]; then
  cat <<EOF > /etc/plymouth/plymouthd.conf
[Daemon]
Theme=${puavo_boot_plymouth_theme}
EOF
fi

for x in $(cat /proc/cmdline); do
  case "$x" in
    modprobe.blacklist=r8169) r8169_blacklisted=true ;;
  esac
done

if $r8169_blacklisted; then
  cat <<'EOF' > /etc/modprobe.d/r8168-dkms.conf
alias   pci:v00001186d00004300sv00001186sd00004B10bc*sc*i*      r8168
alias   pci:v000010ECd00008168sv*sd*bc*sc*i*                    r8168
EOF
fi
