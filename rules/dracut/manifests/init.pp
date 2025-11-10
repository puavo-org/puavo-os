class dracut {
  include ::packages

  file {
    # in Puavo OS we create these at image build in our own way
    '/etc/kernel/postinst.d/dracut':
      ensure  => link,
      require => Package['dracut'],
      target  => '/usr/bin/true';

    '/etc/dracut.conf.d/puavo.conf':
      require => Package['dracut'],
      source  => 'puppet:///modules/dracut/etc_dracut.conf.d_puavo.conf';
  }

  Package <| title == dracut |>
}
