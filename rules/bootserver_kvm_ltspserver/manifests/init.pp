class bootserver_kvm_ltspserver {
  include ::puavo

  $default_ltsp_servername = "${puavo_hostname}-ltsp1"

  exec {
    'create a virtual ltsp server':
      command => "/usr/sbin/puavo-create-kvm-ltsp-server '$default_ltsp_servername'",
      unless  => "/usr/bin/virsh dominfo '$default_ltsp_servername'";
  }

  file {
    '/etc/init/restart-libvirt-autostart-domains.conf':
      source  => 'puppet:///modules/bootserver_kvm_ltspserver/restart-libvirt-autostart-domains.upstart';
    '/etc/puavo/primary_ltsp_server':
      content => "${default_ltsp_servername}\n",
      require => Exec['create a virtual ltsp server'],
      replace => false;
  }
}
