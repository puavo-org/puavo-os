class adm_users {
  include adm_users::common_user,
          app_bash,
          config::logins

  $supplementary_groups = [ 'adm'
                          , 'lpadmin'
                          , $config::logins::admin_user_groupname ]

  define adm_user ($shell, $sshkey, $sshkey_type, $uid, $user_homedir) {
    $adm_user   = $title
    $ssh_subdir = "$user_homedir/.ssh"

    if ($uid < $config::logins::admin_min_uid) or ($config::logins::admin_max_uid < $uid) {
      fail("admin-user uid parameter must be between $config::logins::admin_min_uid and $config::logins::admin_max_uid (was $uid)")
    }

    file {
      $user_homedir:
        ensure  => directory,
        owner   => $adm_user,
        group   => $config::logins::admin_user_groupname,
        mode    => 750,
        require => User[$adm_user];

      $ssh_subdir:
        ensure  => directory,
        owner   => $adm_user,
        group   => $adm_user,
        mode    => 700;
    }

    group {
      $adm_user:
        ensure  => present,
        gid     => $uid;
    }

    ssh_authorized_key {
      "$adm_user maintenance SSH key":
        key     => $sshkey,
        require => File[$ssh_subdir],
        type    => $sshkey_type,
        user    => $adm_user;
    }

    user {
      $adm_user:
        ensure     => present,
        uid        => $uid,
        gid        => $uid,
        groups     => $adm_users::supplementary_groups,
        home       => $user_homedir,
        managehome => true,
        require    => [ File[$config::logins::admin_homedir]
                      , File['/etc/skel/.bashrc']
                      , Group[$adm_user]
                      , Group[$config::logins::admin_user_groupname] ],
        shell      => $shell,
        password   => '!';
    }
  }

  file {
    [ "${config::logins::admin_homedir}"
    , "${config::logins::admin_homedir}/code"
    , "${config::logins::admin_homedir}/code/bin" ]:
      ensure  => directory,
      owner   => 'root',
      group   => $config::logins::admin_user_groupname,
      mode    => 750,
      require => Group[$config::logins::admin_user_groupname];
  }
}
