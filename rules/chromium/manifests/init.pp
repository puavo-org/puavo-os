class chromium {
  include ::dpkg
  include ::packages

  dpkg::simpledivert {
    '/usr/bin/chromium':
      before => File['/usr/bin/chromium'];
  }

  file {
    '/etc/chromium':
      ensure => directory;

    '/etc/chromium/master_preferences':
      source => 'puppet:///modules/chromium/master_preferences';

    '/usr/bin/chromium':
      mode   => '0755',
      source => 'puppet:///modules/chromium/chromium';
  }

  Package <| title == chromium |>
}
