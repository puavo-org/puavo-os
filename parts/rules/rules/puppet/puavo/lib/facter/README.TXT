puavofacts.rb must not be renamed to puavo.rb!  Puppet will end up
loading puavo.rb from /usr/lib/ruby/vendor_ruby/puavo.rb, which is wrong.
The bug is in line /usr/lib/ruby/1.8/puppet/indirector/facts/facter.rb:96,
in "load"-command.  Reporting this should be nice.
