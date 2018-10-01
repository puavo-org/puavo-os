class nagios::check {
  include ::nagios

  define check ($cmdline) {
    $checkname = $title

    file {
      "/etc/nagios/nrpe.d/${checkname}.cfg":
        content => "command[${checkname}]=${cmdline}\n",
        notify  => Service['nagios-nrpe-server'];
    }
  }

  define check_disk ($check_tags) {
    $check_partition = $title
    $check_name = regsubst(regsubst($check_partition, '^', 'check_disk'),
			   '/',
			   '_',
			   'G')

    @check {
      $check_name:
        cmdline => "/usr/lib/nagios/plugins/check_disk -w 10% -c 5% -W 10% -K 5% -p ${check_partition}",
        tag     => $check_tags;
    }
  }
}
