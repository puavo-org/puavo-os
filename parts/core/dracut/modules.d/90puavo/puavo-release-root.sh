#!/bin/sh

# The mounts containing the images block unmounting the old root,
# and thus closing the image device. Move them out of the way. Which
# ones are mounted depends on the installation.

for name in images installimages .puavo .puavoinstaller; do
  grep -q " /oldroot/${name} " /proc/mounts || continue

  mkdir -p "/oldsys/${name}"
  mount --move "/oldroot/${name}" "/oldsys/${name}" \
    || warn "failed to move /oldroot/${name} out of the old root"
done
