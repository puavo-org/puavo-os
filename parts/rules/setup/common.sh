# /bin/sh fragment

setup() {
  rootdir=$1; shift
  srcdir=$1 ; shift

  setup_buildsrc $srcdir $rootdir
  run_scripts $rootdir $*
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
