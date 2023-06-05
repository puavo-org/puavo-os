class puavo_suspend_tricks {

  file {
    '/lib/systemd/system-sleep/puavo-suspend-tricks':
      mode    => '0755',
      source  => 'puppet:///modules/puavo_suspend_tricks/puavo-suspend-tricks';
  }

  Package <| title == systemd |>
}
