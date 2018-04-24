class adm::update_admins {
  file {
    '/usr/local/sbin/puavo-update-admins':
      mode   => '0755',
      source => 'puppet:///modules/adm/puavo-update-admins';
  }
}
