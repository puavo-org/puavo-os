class apt::repositories {
  include apt

  file {
    '/etc/apt/apt.conf.d/00ltspbuild-proxy':
      content => "acquire::http::proxy \"${apt::proxy_url}\";\n";

    '/etc/apt/sources.list':
      content => template('apt/sources.list'),
      notify  => Exec['apt update'],
      require => File['/etc/apt/apt.conf.d/00ltspbuild-proxy'];

    # removes the file "/etc/apt/apt.conf.d/00ltspbuild-proxy" (above) at boot
    '/etc/init/remove-apt-proxy.conf':
      content => template('apt/remove-apt-proxy.conf');

    '/etc/init.d/remove-apt-proxy':
      ensure => link,
      target => '/lib/init/upstart-job';
  }

  # define some apt keys and repositories for use
  @apt::repository {
    'partner':
      aptline => "http://archive.canonical.com/ubuntu $lsbdistcodename partner";
  }
}
