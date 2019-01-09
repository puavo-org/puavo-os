class pam {
  file {
    '/etc/pam.d/gdm-autologin':
      source => 'puppet:///modules/pam/gdm-autologin';

    '/etc/pam.d/gdm-password':
      source => 'puppet:///modules/pam/gdm-password';

    '/etc/pam.d/i3lock':
      source => 'puppet:///modules/pam/i3lock';

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
}
