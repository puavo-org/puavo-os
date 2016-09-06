class packages::proposed_updates {
  define for_packages ($packagelist) {
    $filename = $title

    file {
      "/etc/apt/preferences.d/${filename}.pref":
        content =>
          sprintf("%s%s%s",
                  inline_template("Package: <%= @packagelist.join(' ') %>\n"),
                  "Pin: release a=${lsbdistcodename}-proposed\n",
                  "Pin-Priority: 600\n");
    }
  }

  for_packages {
    'libwnck3':
      packagelist => [ 'libwnck-3-0', 'libwnck-3-common', ];
  }
}
