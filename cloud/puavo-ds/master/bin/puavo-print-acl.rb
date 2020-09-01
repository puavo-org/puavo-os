#!/usr/bin/ruby

require 'puavo-ds/database_acl'

suffix = 'dc=edu,dc=juhaerk,dc=net'
samba_domain = 'EDUJUHAERK'

puts LdapAcl.generate_acls(suffix, samba_domain)
