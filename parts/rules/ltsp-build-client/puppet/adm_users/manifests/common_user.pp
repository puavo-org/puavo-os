class adm_users::common_user {
  include adm_users,
          config::logins

  $homedir = "${config::logins::admin_homedir}/${config::logins::admin_user_username}"

  file {
    $homedir:
      ensure  => directory,
      owner   => $config::logins::admin_user_username,
      group   => $config::logins::admin_user_groupname,
      mode    => 750,
      require => [ File [ $config::logins::admin_homedir        ]
                 , Group[ $config::logins::admin_user_groupname ]
                 , User [ $config::logins::admin_user_username  ] ];
  }

  group {
    $config::logins::admin_user_groupname:
      ensure => present,
      gid    => $config::logins::admin_user_gid;
  }

  user {
    $config::logins::admin_user_username:
      ensure  => present,
      gid     => $config::logins::admin_user_gid,
      uid     => $config::logins::admin_user_uid;
  }
}
