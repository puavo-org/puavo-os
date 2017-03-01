class xorg_inputs_calibration {
  include ::puavo_conf

  ::puavo_conf::definition {
    'puavo-xorg-inputs-calibration.json':
      source => 'puppet:///modules/xorg_inputs_calibration/puavo-xorg-inputs-calibration.json';
  }

  ::puavo_conf::script {
    'setup_xorg_inputs_calibration':
      require => Puavo_conf::Definition['puavo-xorg-inputs-calibration.json'],
      source  => 'puppet:///modules/xorg_inputs_calibration/setup_xorg_inputs_calibration';
  }
}
