class packages::pinning {
  define for_packages ($packagelist, $target_release, $priority=995) {
    $filename = $title

    file {
      "/etc/apt/preferences.d/${filename}.pref":
        content =>
          sprintf("%s%s%s",
                  inline_template("Package: <%= @packagelist.join(' ') %>\n"),
                  "Pin: release a=${target_release}\n",
                  "Pin-Priority: ${priority}\n");
    }
  }
}
