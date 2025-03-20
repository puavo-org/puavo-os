class exammode {
  include ::exammode::common

  $puavo_exammode_dir = '/var/lib/puavo-exammode'

  file {
    '/etc/dbus-1/system.d/org.puavo.Exam.conf':
      source => 'puppet:///modules/exammode/org.puavo.Exam.conf';

    '/usr/local/bin/puavo-exammode-ctrl':
      mode   => '0755',
      source => 'puppet:///modules/exammode/puavo-exammode-ctrl';

    '/usr/local/sbin/puavo-exammode-manager':
      mode    => '0755',
      require => [ Package['ruby-eventmachine']
                 , Package['ruby-faye-websocket'] ],
      source  => 'puppet:///modules/exammode/puavo-exammode-manager';

    '/usr/share/dbus-1/system-services/org.puavo.Exam.service':
      source => 'puppet:///modules/exammode/org.puavo.Exam.service';
  }

  Package <|
       title == 'ruby-eventmachine'
    or title == 'ruby-faye-websocket'
  |>
}
