class puavo_pkg {
  include ::packages

  $pkgbasedir = '/usr/share/puavo-pkg/packages'

  # This is the default PUAVO_PKG_ROOTDIR for puavo-pkg that can be changed
  # in /etc/puavo-pkg/puavo-pkg.conf.
  $pkgrootdir = '/var/lib/puavo-pkg'

  define install () {
    $pkgname        = $title
    $pkgpath        = "${puavo_pkg::pkgbasedir}/${pkgname}.tar.gz"
    $installed_link = "${puavo_pkg::pkgrootdir}/installed/${pkgname}"

    exec {
      "/usr/sbin/puavo-pkg install ${puavo_pkg::pkgbasedir}/${pkgname}.tar.gz":
        require => Package['puavo-pkg'],
        timeout => 7200,	# 2 hours = 7200 seconds, should be enough
        unless  => "/usr/bin/test \"\$(readlink \"${installed_link}\" | xargs basename)\" = \"\$(tar --wildcards -Ozx -f \"${pkgpath}\" '*/.puavo-pkg-version' | awk '\$1 == \"package-id\" { print \$2 }')\"";
    }
  }

  Package <| title == puavo-pkg |>
}
