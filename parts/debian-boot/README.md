# Debian boot for puavo-os images

This repository contains the bits and pieces needed to boot OS from an image 
file based on puavo-os. The boot process can be initiated either using GRUB2 
or PXE booting.

How the image is mounted and whether local partitions are mounted depends on 
the kernel command line parameters.


## Laptops and other locally booting devices

### Partitioning

The default partitioning is done using LVM2 with a single volume group 
called puavo that has the following logical volumes:

* home
* imageoverlays
* images
* state
* swap
* tmp

### GRUB2

Grub2 is installed on MBR and /boot is located normally on partition 
/dev/mapper/puavo-images under /boot directory.

GRUB needs a BIOS boot partition for EFI boot.

Installer needs support for both 32-bit and 64-bit UEFI BIOSes.

## Netboot devices

By default netboot devices boot using PXE, but it is also possible to load 
kernel and initrd image from a local media and continue mounting the root 
file system over NBD.

Netboot devices can also use local partitions if they are available.


## initramfs

## Boot parameters

Puavo specific boot parameters are prefixed with "puavo." 

The boot process is initiated by setting boot=puavo parameter that replaces
the normal boot script named "local".

init=/sbin/init-puavo
  Required to initiate the Puavo specific boot process. Without this normal 
  boot is run.

puavo.bootmode
  Bootmode defines whether the system should be running from the local 
  disk or using network mounted filesystem or mixed.

  local -   Mount all partitions locally, e.g. a laptop
  netboot - Mount root partition using nbd
  cached -  Mount root partition using nbd caching and use local swap and
            /tmp partitions if available. If grub is installed locally, it 
            uses pxegrub to load kernel and initrd.img from the server so
            that they match the image. Caching is done using xnbd-client.

  When using the local mode all partitions are mounted automatically. When 
  using netboot or mixed mode all partitions defined on the command 
  line using puavo.lvm.lv.xxx directives are mounted.

puavo.hosttype [optional]
  Force hosttype. The image itself defines which hosttypes are allowed and 
  what the hosttype actually means. Normally the hosttype is defined in Puavo,
  but this value can be used to override the setting. This can be useful in 
  special purpose USB images or images that do not connect to Puavo at all.

puavo.image.name
  Filename of the image that is mounted from partition defined in 
  puavo.partition.images or mounted through NBD

puavo.image.fstype [optional]
  Filesystem type of the image file if it cannot be determined automatically.

puavo.image.overlay [optional]
  Name of the overlay profile to use. The profile directory is created
  under <puavo.partition.imageoverlays>/<puavo.image.filename>/. The profile
  directory acts as overlayfs upper directory for the given image and 
  is discarded when the image is updated.

puavo.lvm.vg [optional]
  LVM volume group name that contains the local partitions. By default this 
  is "puavo".

puavo.lvm.lv.home [optional]
puavo.lvm.lv.images [optional]
puavo.lvm.lv.imageoverlays [optional]
puavo.lvm.lv.state [optional]
puavo.lvm.lv.swap [optional]
puavo.lvm.lv.tmp [optional]
  Names of the LVM logical volumes that should be mounted locally. These 
  should be placed under volume group defined in puavo.lvm.vg.

  These default to home, images, imageoverlays, state, swap and tmp when
  puavo.bootmode is set to "local". Otherwise there are no defaults.

# Initrd steps

## Mount image and partitions

On Debian initramfs is modified to support mounting a squashfs image 
file from the image partition. On Ubuntu this is also supported using loop= 
directive.



The boot=puavo directive instructs Debian's initramfs-tools' init script
to load puavo specific init script that overrides mountroot() method. The 
script is located in path:

/usr/share/initramfs-tools/scripts/puavo

--------------------------------------------------------------------------------
puavo_postmount_root()
{
        if [ "${puavo_postmount_used}" != "yes" ]; then
                [ "$quiet" != "y" ] && log_begin_msg "Running /scripts/puavo-postmount"
                run_scripts /scripts/puavo-postmount
                [ "$quiet" != "y" ] && log_end_msg
        fi
        puavo_postmount_used=yes
}

mountroot()
{
        local_mount_root
        puavo_postmount_root
}
--------------------------------------------------------------------------------


After the root device defined on the kernel command line is mounted, the 
puavo script calls all scripts under directory:

/usr/share/initramfs-tools/scripts/puavo-postmount

These scripts take care of mounting the overlay filesystem and the local 
partitions.
