class autopoweroff {
  include packages

  # XXX Ideally, the autopoweroff package would do the right thing,
  # XXX but it is easier to fix it here rather than fix the package.
  # XXX Besides, we only need to touch stuff under /etc,
  # XXX and could use this to setup a sane default.

  file {
    '/etc/autopoweroff.conf':
      before  => Package['autopoweroff'],
      content => "",
      replace => false;         # do not replace, may be set at ltsp boot

    '/etc/init.d/autopoweroff':
      ensure  => link,
      target  => '/lib/init/upstart-job',
      require => File['/etc/init/autopoweroff.conf'];

    '/etc/init/autopoweroff.conf':
      content => template('autopoweroff/init_autopoweroff.conf'),
      require => Package['autopoweroff'];
  }

  Package <| title == autopoweroff |>
}
