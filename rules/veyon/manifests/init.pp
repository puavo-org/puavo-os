class veyon {
  include ::puavo_conf

  ::puavo_conf::script {
    'get_veyon_keys':
      source => 'puppet:///modules/veyon/get_veyon_keys';
  }
}
