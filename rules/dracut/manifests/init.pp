class dracut {
  include ::packages

  file {
    '/etc/dracut.conf.d/puavo.conf':
      require => Package['dracut'],
      source  => 'puppet:///modules/dracut/etc_dracut.conf.d_puavo.conf';
  }

  Package <| title == dracut |>
}
