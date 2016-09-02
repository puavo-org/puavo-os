class bootserver_racoon {
  package {
    'racoon':
      ensure => purged; # IPSec was never configured properly and was
                        # never used in production. Nevertheless,
                        # racoon and all other ipsec-related stuff was
                        # installed. Now we get rid of it.
  }
}
