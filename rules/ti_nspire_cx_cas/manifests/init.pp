class ti_nspire_cx_cas {
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-ti-nspire.json':
      source => 'puppet:///modules/ti_nspire_cx_cas/puavo-ti-nspire.json';
  }
}
