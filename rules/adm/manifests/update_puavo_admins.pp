class adm::update_puavo_admins {
  include ::puavo_conf

  ::puavo_conf::script {
    'update_puavo_admins':
      source => 'puppet:///modules/adm/update_puavo_admins';
  }
}
