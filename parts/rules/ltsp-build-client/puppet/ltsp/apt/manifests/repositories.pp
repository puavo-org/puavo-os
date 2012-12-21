class apt::repositories {
  include apt

  file {
    '/etc/apt/apt.conf.d/00ltspbuild-proxy':
      content => "acquire::http::proxy \"${apt::proxy_url}\";\n";

    '/etc/apt/sources.list':
      content => template('apt/sources.list'),
      notify  => Exec['apt update'],
      require => File['/etc/apt/apt.conf.d/00ltspbuild-proxy'];
  }

  # define some apt keys and repositories for use
  @apt::repository {
    'partner':
      aptline => "http://archive.canonical.com/ubuntu $lsbdistcodename partner";
  }
}
