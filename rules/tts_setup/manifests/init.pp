class tts_setup {
  include ::packages

  file {
    [ '/etc/speech-dispatcher', '/etc/speech-dispatcher/modules', ]:
      ensure => directory;

    '/etc/speech-dispatcher/speechd.conf':
      require => Package['speech-dispatcher-pico'],
      source  => 'puppet:///modules/tts_setup/speechd.conf';

    '/etc/speech-dispatcher/modules/festival-generic.conf':
      require => Package['festvox-suopuhe-mv'],
      source  => 'puppet:///modules/tts_setup/festival-generic.conf';

    '/etc/festival.scm':
      require => Package['festvox-suopuhe-mv'],
      source  => 'puppet:///modules/tts_setup/festival.scm';
  }

  Package <| title == festvox-suopuhe-mv and title == speech-dispatcher-pico |>
}
