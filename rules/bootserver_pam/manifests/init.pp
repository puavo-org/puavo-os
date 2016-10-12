class bootserver_pam {
  file {
    '/etc/pam.d/common-auth':
      content => template('bootserver_pam/etc/pam.d/common-auth');
    '/etc/pam.d/common-account':
      content => template('bootserver_pam/etc/pam.d/common-account');
    '/etc/pam.d/common-password':
      content => template('bootserver_pam/etc/pam.d/common-password');
    '/etc/pam.d/common-session':
      content => template('bootserver_pam/etc/pam.d/common-session');
    '/etc/pam.d/common-session-interactive':
      content => template('bootserver_pam/etc/pam.d/common-session-interactive');
    '/etc/pam.d/sshd':
      content => template('bootserver_pam/etc/pam.d/sshd');
  }
}
