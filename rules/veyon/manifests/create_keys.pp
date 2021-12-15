class veyon::create_keys {
  include ::puavo_conf

  ::puavo_conf::script {
    'create_veyon_keys':
      source => 'puppet:///modules/veyon/create_veyon_keys';
  }
}
