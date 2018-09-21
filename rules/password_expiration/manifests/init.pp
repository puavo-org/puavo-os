class password_expiration {
  include ::packages
  include ::puavo_conf

  file {
    '/etc/xdg/autostart/puavo-handle-user-password-expiration.desktop':
      source => 'puppet:///modules/password_expiration/puavo-handle-user-password-expiration.desktop';

    '/usr/local/bin/puavo-handle-user-password-expiration':
      mode    => '0755',
      require => Package['chromium'],
      source  => 'puppet:///modules/password_expiration/puavo-handle-user-password-expiration';
  }

  ::puavo_conf::definition {
    'puavo-passwords.json':
      source => 'puppet:///modules/password_expiration/puavo-passwords.json';
  }

  Package <| title == chromium |>
}
