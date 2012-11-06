class organisation_adm_users {
  include adm_users,
          config::logins

  # an example admin user
  adm_users::adm_user {
    'testadmin':
      shell        => '/bin/bash',
      sshkey       => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA6QHOMB2SjyX22c5tGBdhB56z66L0jBt21ovq9gd3JWo/XlwcnxuaTqQI3Djd2kAiDn95dJMFPK6Y4jFg3BjqM1kZemFC8kL34qBvkwhB48zFrViophnI2h+qwil6YY+DJnEavTzqpbawGcJbIawwCpUoYWe/qe6/08ZNITM2aMUBzZ7dTQgFU/lNrqQDlx1HPLqsFenSTWt8DjKDs8Si+Ef8C4nb7Btvq1LhnR1V3Xo3ksnURH0w57N8Zrdp400GgJzXnc78H5saV9ybd9xGgJ8cjDdlfT1WYI2rXIyGxy0e3WY7dfEBZutVVPQQoXr3NXviJUvz6ydJf5O+Ub8cSw==',
      sshkey_type  => 'rsa',
      uid          => 1001,
      user_homedir => "${config::logins::admin_homedir}/testadmin";
  }
}
