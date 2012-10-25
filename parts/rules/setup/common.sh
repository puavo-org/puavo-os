# /bin/sh fragment

setup() {
  rootdir=$1; shift
  srcdir=$1 ; shift

  mount -t proc proc $rootdir/proc

  setup_buildsrc $srcdir $rootdir
  run_scripts $rootdir $*

  umount $rootdir/proc
}

run_scripts() {
  rootdir=$1; shift
  for script in $*; do
    chroot $rootdir /etc/build/scripts/$script
  done
}

setup_buildsrc() {
  srcdir=$1
  rootdir=$2
  mkdir -p $rootdir/etc/build
  tar -C $srcdir -c . | chroot $rootdir tar -C /etc/build -x
}

server_scripts="
  timezone
  console
  admin_tools
"
