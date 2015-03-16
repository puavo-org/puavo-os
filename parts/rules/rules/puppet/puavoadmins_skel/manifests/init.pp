class puavoadmins_skel {

  file {
    ['/etc', '/etc/puavoadmins', '/etc/puavoadmins/skel']:
      ensure => directory;

    '/etc/puavoadmins/skel/.bashrc':
      content => template('puavoadmins_skel/bashrc');
  }

}
