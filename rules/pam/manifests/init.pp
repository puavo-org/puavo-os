class pam {
  include ::packages

  $pam_packages = [ 'libpam-ccreds'
                  , 'libpam-gnome-keyring'
                  , 'libpam-krb5'
                  , 'libpam-ldapd'
                  , 'libpam-modules'
                  , 'libpam-runtime'
                  , 'libpam-systemd'
                  , 'puavo-pam' ]

  File { require => Package[$pam_packages] }
  file {
    '/etc/pam.d/common-account':
      source => 'puppet:///modules/pam/common-account';

    '/etc/pam.d/common-auth':
      source => 'puppet:///modules/pam/common-auth';

    '/etc/pam.d/common-password':
      source => 'puppet:///modules/pam/common-password';

    '/etc/pam.d/common-session':
      source => 'puppet:///modules/pam/common-session';

    '/etc/pam.d/common-session-noninteractive':
      source => 'puppet:///modules/pam/common-session-noninteractive';

    '/etc/pam.d/cups':
      source => 'puppet:///modules/pam/cups';

    '/etc/pam.d/gdm-autologin':
      source => 'puppet:///modules/pam/gdm-autologin';

    '/etc/pam.d/gdm-password':
      source => 'puppet:///modules/pam/gdm-password';

    '/etc/pam.d/i3lock':
      source => 'puppet:///modules/pam/i3lock';

    '/etc/pam.d/polkit-1':
      source => 'puppet:///modules/pam/polkit-1';

    '/etc/pam.d/puavo-cached-auth':
      source => 'puppet:///modules/pam/puavo-cached-auth';

    '/etc/pam.d/slock':
      source => 'puppet:///modules/pam/slock';

    '/etc/pam.d/sudo':
      source => 'puppet:///modules/pam/sudo';

    # unfortunately this is necessary... libpam-ccreds should
    # follow the "ccredsfile=" option, but when unlocking from
    # a screensaver such as i3lock, it uses the default database :-(
    '/var/cache/.security.db':
      ensure => link,
      target => 'ccreds/ccreds.db';
  }

  Package <| title == $pam_packages |>
}
