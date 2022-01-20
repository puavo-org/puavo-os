class tts_setup {
  include ::packages

  file {
    [ '/etc/speech-dispatcher', '/etc/speech-dispatcher/modules', ]:
      ensure => directory;

    '/etc/speech-dispatcher/speechd.conf':
      require => Package['speech-dispatcher-pico'],
      source  => 'puppet:///modules/tts_setup/speechd.conf';

    '/etc/speech-dispatcher/modules/pico-generic.conf':
      require => Package['speech-dispatcher-pico'],       
      source  => 'puppet:///modules/tts_setup/pico-generic.conf';

    '/etc/speech-dispatcher/modules/festival-generic.conf':
      require => Package['festvox-suopuhe-mv'],
      source  => 'puppet:///modules/tts_setup/festival-generic.conf';

    '/etc/festival.scm':
      require => Package['festival'],
      source  => 'puppet:///modules/tts_setup/festival.scm';

    '/usr/bin/puavo-festival-read':
      mode    => '0755',
      require => Package['festvox-suopuhe-mv'],
      source  => 'puppet:///modules/tts_setup/puavo-festival-read';
  }

  Package <| title == festvox-suopuhe-mv and title == speech-dispatcher-pico |>
}
