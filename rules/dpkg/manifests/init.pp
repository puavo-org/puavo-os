class dpkg {
  define divert ($dest) {
    exec {
      "dpkg-divert-$title":
        command => "/usr/bin/dpkg-divert --rename --divert \"$dest\" --add \"$title\"",
        onlyif  => "/usr/bin/test -z \"$(dpkg-divert --list \"$title\")\"";
    }
  }

  define simpledivert () {
    ::dpkg::divert { $title: dest => "${title}.distrib"; }
  }

  define statoverride ($owner, $group, $mode) {
    exec {
      "dpkg-statoverride-$title":
        command => "/usr/bin/dpkg-statoverride --update --add $owner $group $mode \"$title\"",
        onlyif  => "/usr/bin/test -z \"$(dpkg-statoverride --list \"$title\")\"";
    }
  }
}
