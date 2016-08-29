class adm {
  include packages

  $home_basedir = '/adm-home'
  $uid_min      = '1000'
  $uid_max      = '1099'

  define user ($uid, $sshkey=undef, $sshkey_type=undef, $shell='/bin/bash') {
    $username   = $title
    $homedir    = "${adm::home_basedir}/${username}"
    $ssh_subdir = "$homedir/.ssh"

    if ($uid < $adm::uid_min) or ($adm::uid_max < $uid) {
      fail("adm::user uid parameter must be between $adm::uid_min and $adm::uid_max (was $uid)")
    }

    file {
      $homedir:
        ensure  => directory,
        owner   => $username,
        group   => $username,
        mode    => 750,
        require => User[$username];

      $ssh_subdir:
        ensure  => directory,
        owner   => $username,
        group   => $username,
        mode    => 700;
    }

    group {
      $username:
        ensure  => present,
        gid     => $uid;
    }

    if $sshkey != undef {
      ssh_authorized_key {
        "$username maintenance SSH key":
          key     => $sshkey,
          require => File[$ssh_subdir],
          type    => $sshkey_type,
          user    => $username
      }
    }

    user {
      $username:
        ensure     => present,
        uid        => $uid,
        gid        => $uid,
        groups     => [ 'adm', 'lpadmin' ],
        home       => $homedir,
        require    => [ File['/etc/skel/.bashrc']
                      , Group[$username]
                      , Package['cups-client'] ],
        shell      => $shell,
        password   => '!';
    }
  }

  file {
    '/etc/bash.bashrc':
      content => template('adm/bash.bashrc');

    '/etc/skel/.bashrc':
      content => template('adm/etc_skel_.bashrc');

    $adm::home_basedir:
      ensure  => directory;
  }

  Package <| title == "cups-client" |>
}
