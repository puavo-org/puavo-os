class packages::backports {
  define for_packages ($packagelist) {
    $filename = $title

    file {
      "/etc/apt/preferences.d/${filename}.pref":
        content =>
          sprintf("%s%s%s",
                  inline_template("Package: <%= @packagelist.join(' ') %>\n"),
                  "Pin: release a=${lsbdistcodename}-backports\n",
                  "Pin-Priority: 995\n");
    }
  }

  ::packages::backports::for_packages {
    'linux-image':
      packagelist => [ 'linux-base', ];
  }
}
