# /bin/sh fragment

run_scripts() {
  rootdir=$1  ; shift
  scriptdir=$1; shift
  for script in $*; do
    $scriptdir/$script $rootdir
  done
}

server_scripts="
  set_timezone
  set_console
"
