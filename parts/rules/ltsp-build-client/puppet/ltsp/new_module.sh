#!/bin/sh

set -e

modulename=$1

if [ -z "$modulename" ]; then
  echo "Usage: $(basename $0) modulename" > /dev/stderr
  exit 1
fi

mkdir -p $modulename/manifests
cat <<-EOF > $modulename/manifests/init.pp
	class $modulename {
	  # ...
	}
	EOF
