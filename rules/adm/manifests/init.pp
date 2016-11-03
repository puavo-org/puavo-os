class adm {
  include ::bash
  include ::packages

  $common_group     = 'puavo-os'
  $common_group_gid = 1000
  $home_basedir     = '/adm-home'
  $uid_max          = 1099
  $uid_min          = 1000

  define user ($uid, $sshkey=undef, $sshkey_type=undef, $homedir=undef,
               $shell='/bin/bash', $home_mode='0750') {
    $username = $title

    $user_homedir = $homedir ? {
		      undef   => "${adm::home_basedir}/${username}",
		      default => $homedir,
		    }
    $ssh_subdir = "${user_homedir}/.ssh"

    if ($uid < $adm::uid_min) or ($adm::uid_max < $uid) {
      fail("adm::user uid parameter must be between $adm::uid_min and $adm::uid_max (was $uid)")
    }

    file {
      $user_homedir:
        ensure  => directory,
        owner   => $username,
        group   => $username,
        mode    => $home_mode,
        require => User[$username];

      $ssh_subdir:
        ensure  => directory,
        owner   => $username,
        group   => $username,
        mode    => '0700';

      "${user_homedir}/.bash_by_puppet":
        owner   => $username,
        group   => $username,
        mode    => '0644',
        source  => [ "puppet:///modules/adm/users/$username/.bash_by_puppet"
                   , "puppet:///modules/adm/common/.bash_by_puppet" ];

      "${user_homedir}/.gitconfig":
        owner   => $username,
        group   => $username,
        mode    => '0644',
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
        home       => $user_homedir,
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
      mode    => '0440';

    $adm::home_basedir:
      ensure  => directory;
  }

  # sets up $common_group as well.
  adm::user {
    'puavo-os':
      homedir   => '/puavo-os',
      home_mode => '02775',
      uid       => 1000;
  }

  Package <| title == "cups-client"
          or title == "sudo" |>
}
