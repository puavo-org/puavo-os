class adm {
  include bash,
          packages

  $common_group     = 'puavo-os'
  $common_group_gid = 1000
  $home_basedir     = '/adm-home'
  $uid_max          = '1099'
  $uid_min          = '1000'

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

      "$homedir/.bash_by_puppet":
        owner   => $username,
        group   => $username,
        mode    => 644,
        source  => [ "puppet:///modules/adm/users/$username/.bash_by_puppet"
                   , "puppet:///modules/adm/common/.bash_by_puppet" ];

      "$homedir/.gitconfig":
        owner   => $username,
        group   => $username,
        mode    => 644,
        source  => [ "puppet:///modules/adm/users/$username/.gitconfig"
                   , "puppet:///modules/adm/common/.gitconfig" ];
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
        groups     => [ 'adm', 'lpadmin', $adm::common_group ],
        home       => $homedir,
        managehome => true,
        require    => [ File['/etc/skel/.bashrc']
                      , Group[$username]
                      , Package['cups-client'] ],
        shell      => $shell,
        password   => '!';
    }
  }

  file {
    '/etc/sudoers.d/puavo-os':
      content => template('adm/sudoers.d/puavo-os'),
      mode    => 440;

    $adm::home_basedir:
      ensure  => directory;
  }

  # sets up $common_group as well.
  adm::user {
    'puavo-os':
      uid => 1000;
  }

  Package <| title == "cups-client"
          or title == "sudo" |>
}
