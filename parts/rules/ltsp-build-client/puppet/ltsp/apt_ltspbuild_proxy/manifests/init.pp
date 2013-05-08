class apt_ltspbuild_proxy {
  include apt::repositories

  $proxy_url = "http://localhost:3142"

  file {
    '/etc/apt/apt.conf.d/00ltspbuild-proxy':
      before  => File['/etc/apt/sources.list'],
      content => "acquire::http::proxy \"${proxy_url}\";\n";

    # removes the file "/etc/apt/apt.conf.d/00ltspbuild-proxy" (above) at boot
    '/etc/init/remove-apt-proxy.conf':
      content => template('apt/remove-apt-proxy.conf');

    '/etc/init.d/remove-apt-proxy':
      ensure => link,
      target => '/lib/init/upstart-job';
  }
}
