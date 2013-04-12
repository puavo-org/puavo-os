class lightdm::login_prompt_as_default {
  # The point of this class is to make sure that we have a generic
  # login prompt at startup, and *not* guest user choice or any other.

  include lightdm
  require packages

  File { owner => 'lightdm', group => 'lightdm', }
  file {
    '/var/lib/lightdm/.cache':
      ensure => directory,
      mode   => 700;

    '/var/lib/lightdm/.cache/unity-greeter':
      ensure => directory,
      mode   => 775;

    '/var/lib/lightdm/.cache/unity-greeter/state':
      content => template('lightdm/unity-greeter_state'),
      mode    => 664;
  }
}
