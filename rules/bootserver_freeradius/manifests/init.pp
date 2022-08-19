class bootserver_freeradius {
  include ::puavo_conf

  ::puavo_conf::script {
    'setup_freeradius':
      source => 'puppet:///modules/bootserver_freeradius/setup_freeradius';
  }
}
