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

puavo.hosttype
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
