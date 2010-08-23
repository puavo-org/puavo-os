#!/usr/bin/ruby
#-*- coding: utf-8 -*-

module PuavoSetup

  #
  # SLAPD handles all configuration related to OpenLDAP (slapd).
  #

  class SLAPD
    require "ldap"
    require 'rubygems'
    require "socket"
    require "./lib/settings.rb"

    def self.newpass( len )
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      newpass = ""
      1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
      return newpass
    end

    def self.ldap_search_dns(dbsettings, base, filter)
      conn = LDAP::Conn.new(host='127.0.0.1', port=389)
      conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
          
      if dbsettings.rootdn and dbsettings.rootpw
        rootdn = dbsettings.rootdn
        rootpw = dbsettings.rootpw
      else
        rootdn = dbsettings.server.connect_dn
        rootpw = dbsettings.server.connect_password
      end

      dns = []

      conn.bind(rootdn, rootpw) do
        begin
          puts "--------------------------------------------"
          puts "finding #{base} #{filter}"

          begin
            conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, filter) {|e|
              dns << e.dn
            }
          rescue LDAP::ResultError
          end
        end
      end

      return dns
    end

    def self.add_entry_if_missing(dbsettings, dn, ldif)
      conn = LDAP::Conn.new(host='127.0.0.1', port=389)
      conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)

      if dbsettings.rootdn and dbsettings.rootpw
        rootdn = dbsettings.rootdn
        rootpw = dbsettings.rootpw
      else
        rootdn = dbsettings.server.connect_dn
        rootpw = dbsettings.server.connect_password
      end

      conn.bind(rootdn, rootpw) do
        begin
          exists = false
          
          #      puts "Checking #{dn}"

          begin
            conn.search(dn, LDAP::LDAP_SCOPE_BASE, "(objectclass=*)") {|e|
              puts "* #{dn} already exists, not adding..."
              exists = true
            }
          rescue LDAP::ResultError
          end
          
          if !exists
            puts "* Adding #{dn}..."

            begin
              conn.add(dn, ldif)
            rescue LDAP::ResultError
#              puts "failed"
              conn.perror("Adding entry failed")
            end
          end
        end
      end
    end

    def self.delete_entry(dbsettings, dn)
      conn = LDAP::Conn.new(host='127.0.0.1', port=389)
      conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)

      if dbsettings.rootdn and dbsettings.rootpw
        rootdn = dbsettings.rootdn
        rootpw = dbsettings.rootpw
      else
        rootdn = dbsettings.server.connect_dn
        rootpw = dbsettings.server.connect_password
      end

      conn.bind(rootdn, rootpw) do
        begin
          begin
            puts "Deleting dn #{dn}"

            conn.delete(dn)
          rescue LDAP::ResultError
            conn.perror("delete")
          end
        end
      end
    end

    def self.edit_entry(dbsettings, dn, ldif)
      if dbsettings.rootdn and dbsettings.rootpw
        rootdn = dbsettings.rootdn
        rootpw = dbsettings.rootpw
      else
        rootdn = dbsettings.server.connect_dn
        rootpw = dbsettings.server.connect_password
      end

      conn = LDAP::Conn.new(host='127.0.0.1', port=389)
      conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
      conn.bind(rootdn, rootpw) do
        #    conn.perror("bind")
        begin
          begin
            conn.modify(dn, ldif)
            puts "* Modified entry #{dn}..."
          rescue LDAP::ResultError => e
            puts "* ERROR: Failed to modify entry #{dn}!#{e.inspect}"
          end
        end
      end
    end

    def self.add_schema(schema)
      puts "adding schema #{schema}"

      if File.exists?("schema/#{schema}.ldif")
        print `ldapadd -Q -Y EXTERNAL -H ldapi:/// -f schema/#{schema}.ldif`
      elsif File.exists?("/etc/ldap/schema/#{schema}.ldif")
        print `ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/#{schema}.ldif`
      end

      ldapdump = `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config cn=*#{schema} 2>/dev/null | grep dn:`

      return ldapdump == ""
    end

    def self.setup_global_acl
      ldif =<<EOF
dn: olcDatabase\={-1}frontend,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.exact=cn=localroot,cn=config manage by dn.exact=uid=admin,o=puavo manage by * break
olcAccess: {1}to dn.base="cn=subschema" by * read
olcAccess: {2}to dn.base="" by * read
EOF

      `echo "#{ldif}" | ldapmodify -c -Y EXTERNAL -H ldapi:/// 2> /dev/null`
    end

    def self.setup_modules(modules)
      tmp_modules = ""
      added_modules = []
      
      modules.each do |mod|
        ldapdump = `ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(&(cn=module*)(olcModuleLoad=#{mod}))" #{mod} 2>/dev/null | grep dn:`
        
        if !ldapdump.empty?
#          puts "* Module #{mod} loaded, not adding..."
        else
#          puts "* Adding modules #{mod}..."
          tmp_modules += "olcModuleload: #{mod}\n"
          added_modules << mod
        end
      end

      if !tmp_modules.empty?
        ldif =<<EOF
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath: /usr/lib/ldap
#{tmp_modules}
EOF

        `echo "#{ldif}" | ldapadd -c -Y EXTERNAL -H ldapi:/// 2> /dev/null`
      end

      return added_modules
    end
    
    def database_exists?(dbsettings)
      suffix = dbsettings.suffix

      path = "/var/lib/ldap/#{suffix}"

      ldapdump = `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b cn=config "(&(olcSuffix=#{suffix})(objectClass=olcDatabaseConfig))" 2>/dev/null | grep dn:`

      if !ldapdump.empty?
        return true
      end

      return false
    end

    def self.create_database(dbsettings)
      rootdn = dbsettings.rootdn
      rootpw = dbsettings.rootpw
      suffix = dbsettings.suffix

      path = "/var/lib/ldap/#{suffix}"
      
      if File.directory?(path)
        puts "Path #{path} exists, not touching it..."
      else
        puts "Creating path #{path}..."
        
        if Dir.mkdir(path, 0700)
          `chown openldap.openldap "#{path}"`
          puts "Created #{path}"
        else
          puts "Failed to create #{path}, exiting..."
          exit
        end
      end
      
      ldapdump = `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b cn=config "(&(olcSuffix=#{suffix})(objectClass=olcDatabaseConfig))" 2>/dev/null | grep dn:`
      
      if ldapdump.empty?
        puts "Adding database configuration for suffix #{suffix}..."
        
        ldif =<<EOF
dn: olcDatabase=hdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: hdb
olcDbDirectory: #{path}
olcSuffix: #{suffix}
olcDbConfig: set_cachesize 0 2097152 0
olcDbConfig: set_lk_max_objects 1500
olcDbConfig: set_lk_max_locks 1500
olcDbConfig: set_lk_max_lockers 1500
olcLastMod: TRUE
olcDbCheckpoint: 512 30
olcDbIndex: uid pres,eq
olcDbIndex: cn,sn,mail pres,eq,approx,sub
olcDbIndex: objectClass eq
EOF

        if rootdn
          if rootpw
            rootpw_hash=`slappasswd -h "{SSHA}" -s "#{rootpw}"`
            rootpw_hash=rootpw_hash.gsub(/\n/,"")

            ldif +=<<EOF
olcRootDN: #{rootdn}
olcRootPW: #{rootpw_hash}
EOF
          else
            # rootDN is set for all databases because unique overlay makes internal
            # queries with permissions of rootDN. The unique overlay is used to
            # ensure that uids, mail addresses and home directories are unique.
            #
            # see man slapo-unique(5) for more information

            ldif +=<<EOF
olcRootDN: #{rootdn}
EOF
          end
        else
          puts "WARNING: No rootDN set for the database!"
        end

#       `echo "#{ldif}" | ldapadd -Q -c -Y EXTERNAL -H ldapi:/// 2> /dev/null`
        puts `echo "#{ldif}" | ldapadd -Q -c -Y EXTERNAL -H ldapi:///`
      end
    end
    
    def self.initialize_puavo_suffix(dbsettings)
      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['dcObject', 'organization']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'o', ["puavo"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'dc', ["puavo"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ['LDAP root']),
             ]
      
      add_entry_if_missing(dbsettings, "o=puavo", ldif)
      
      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['top', 'puavoIdPool']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'cn', ['IdPool']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'puavoNextUidNumber', ['10000']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'puavoNextGidNumber', ['10000']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'puavoNextId', ['1']),
             ]
      
      add_entry_if_missing(dbsettings, "cn=IdPool,o=Puavo", ldif)

      rootpw_hash=`slappasswd -h "{SSHA}" -s "#{dbsettings.rootpw}"`
      rootpw_hash=rootpw_hash.gsub(/\n/,"")

      puavopw_hash=`slappasswd -h "{SSHA}" -s "#{dbsettings.puavo_user_password}"`.gsub(/\n/,"")

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['account', 'simpleSecurityObject']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'uid', ["admin"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ["Root account with access to everything in LDAP. Used to create new databases and manage database ownership information."]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'userPassword', [rootpw_hash]),
             ]

      add_entry_if_missing(dbsettings, "uid=admin,o=Puavo", ldif)

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['account', 'simpleSecurityObject']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'uid', ["puavo"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ["Account for Puavo to search user DNs"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'userPassword', [puavopw_hash]),
             ]

      add_entry_if_missing(dbsettings, "uid=puavo,o=Puavo", ldif)
    end

    def self.initialize_root(dbsettings)
      domain = dbsettings.domain
      suffix = dbsettings.suffix

      /dc=(.*?),/.match(suffix)
      suffix_dc = $1

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['dcObject', 'organization', 'puavoEduOrg', 'eduOrg']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'o', [domain]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'dc', [suffix_dc]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ["#{dbsettings.org_name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'puavoKerberosRealm', ["#{dbsettings.kerberos_realm}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'puavoDomain', ["#{dbsettings.domain}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'eduOrgLegalName', ["#{dbsettings.org_name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'cn', ["#{dbsettings.org_name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'owner', ["#{dbsettings.server.connect_dn}"]),
             ]
      
      add_entry_if_missing(dbsettings, "#{suffix}", ldif)
    end
    
    def self.initialize_admin_users(dbsettings)
      domain = dbsettings.domain
      suffix = dbsettings.suffix

      kdc_ldappw_hash=`slappasswd -h "{SSHA}" -s "#{dbsettings.kdc_ldappw}"`.gsub(/\n/,"")
      kadmin_ldappw_hash=`slappasswd -h "{SSHA}" -s "#{dbsettings.kadmin_ldappw}"`.gsub(/\n/,"")
      samba_rootpw_hash=`slappasswd -h "{SSHA}" -s "#{dbsettings.samba_rootpw}"`.gsub(/\n/,"")
      
#      ldif = [
#              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['top', 'person']),
#              LDAP.mod(LDAP::LDAP_MOD_ADD, 'cn', ["admin"]),
#              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sn', ["Admin"]),
#              LDAP.mod(LDAP::LDAP_MOD_ADD, 'userPassword', [rootpw_hash]),
#             ]
      
#      add_entry_if_missing(dbsettings, "uid=admin,#{suffix}", ldif)
      
      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['account', 'simpleSecurityObject']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'uid', ["kdc"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ["Kerberos root"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'userPassword', [kdc_ldappw_hash]),
             ]
      
      add_entry_if_missing(dbsettings, "uid=kdc,ou=System Accounts,#{suffix}", ldif)

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['account', 'simpleSecurityObject']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'uid', ["kadmin"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ["Kerberos root"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'userPassword', [kadmin_ldappw_hash]),
             ]

      add_entry_if_missing(dbsettings, "uid=kadmin,ou=System Accounts,#{suffix}", ldif)

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['account', 'simpleSecurityObject']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'uid', ["samba"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ["Samba root"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'userPassword', [samba_rootpw_hash]),
             ]
      
      add_entry_if_missing(dbsettings, "uid=samba,ou=System Accounts,#{suffix}", ldif)
    end

    def self.initialize_ous(dbsettings)
      ['People',
       'Groups',
       'Hosts',
       'Automount',
       'Roles',
       'Services',
       'System Accounts',
       'System Groups',
       'Password Policies',
       'Idmap',
       'Kerberos Realms'].each do |ou|
        ldif = [
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['top', 'organizationalUnit']),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'ou', [ou]),
               ]
        
        add_entry_if_missing(dbsettings, "ou=#{ou},#{dbsettings.suffix}", ldif)

        ['Servers',
         'Devices'].each do |ou|

        ldif = [
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['top', 'organizationalUnit']),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'ou', [ou]),
               ]

        add_entry_if_missing(dbsettings, "ou=#{ou},ou=Hosts,#{dbsettings.suffix}", ldif)
      end
    end

    def self.configure_db_overlays(dbsettings)
      # http://www.openldap.org/doc/admin24/overlays.html
      # http://www.openldap.org/lists/openldap-technical/200912/msg00005.html

      # Find the real dn of the database configuration for the suffix

      suffix = dbsettings.suffix

      ldapdump = `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b cn=config "(&(objectClass=olcDatabaseConfig)(olcSuffix=#{dbsettings.suffix}))" olcSuffix 2>/dev/null | grep dn:`

      if ! ldapdump.empty?
        if /dn: (.*?)\n/.match(ldapdump)
          database = $1

          dns = ldap_search_dns(dbsettings, database, "(objectclass=olcOverlayConfig)")

          dns.each do | dn |
            delete_entry(dbsettings, dn)
          end

          puts "Adding overlays for suffix #{dbsettings.suffix} in #{database}...\n"

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['olcUniqueConfig', 'olcOverlayConfig']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcOverlay', ['{0}unique']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcUniqueURI', ["ldap:///ou=People,#{suffix}?uid?sub",
                                                                "ldap:///ou=People,#{suffix}?mail?sub",
                                                                "ldap:///ou=People,#{suffix}?homeDirectory?sub",
                                                                "ldap:///?sambaSID?sub"]),
                 ]

          add_entry_if_missing(dbsettings, "olcOverlay={0}unique,#{database}", ldif)

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['olcMemberOf', 'olcOverlayConfig']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcOverlay', ['{1}memberof']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfGroupOC', ['puavoEduGroup']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfMemberAD', ['member']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfMemberOfAD', ['memberOf']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfDangling', ['error']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfRefInt', ['TRUE']),
                 ]

          add_entry_if_missing(dbsettings, "olcOverlay={1}memberof,#{database}", ldif)

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['olcMemberOf', 'olcOverlayConfig']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcOverlay', ['{2}memberof']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfGroupOC', ['puavoUserRole']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfMemberAD', ['member']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfMemberOfAD', ['puavoUserRole']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfDangling', ['error']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfRefInt', ['TRUE']),
                 ]

          add_entry_if_missing(dbsettings, "olcOverlay={2}memberof,#{database}", ldif)

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['olcMemberOf', 'olcOverlayConfig']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcOverlay', ['{3}memberof']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfGroupOC', ['puavoUserRole']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfMemberAD', ['puavoMemberGroup']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfMemberOfAD', ['puavoUserRole']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfDangling', ['error']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcMemberOfRefInt', ['TRUE']),
                 ]

          add_entry_if_missing(dbsettings, "olcOverlay={3}memberof,#{database}", ldif)

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['olcConstraintConfig', 'olcOverlayConfig']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcOverlay', ["{4}constraint"]),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcConstraintAttribute', 
                           ["puavoSchool set \"(this/puavoSchool/puavoSchoolAdmin* | [#{dbsettings.suffix}]/owner* & user)\"",
                           ]),
                 ]

#                            "cn,sn,givenName set \"(this/givenName + [ ] + this/sn) & this/cn\"",

          add_entry_if_missing(dbsettings, "olcOverlay={4}constraint,#{database}", ldif)

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['olcSmbKrb5PwdConfig', 'olcOverlayConfig']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcOverlay', ["{5}smbkrb5pwd"]),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcSmbKrb5PwdEnable', ['krb5', 'samba']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcSmbKrb5PwdMustChange', ['2592012']),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcSmbKrb5PwdKrb5Realm', ["#{dbsettings.kerberos_realm}"]),
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcSmbKrb5PwdRequiredClass', ["puavoEduPerson"])
                 ]

          add_entry_if_missing(dbsettings, "olcOverlay={5}smbkrb5pwd,#{database}", ldif)
        end
      end
    end

    def self.setup_certificates(settings)
      tempdir=`mktemp -d`
      tempdir = tempdir.gsub(/\n/,"")

      puts "Using #{settings.ca_fqdn} as CA name and #{settings.server_fqdn} as ldap server name..."
      
      ca_temp =<<EOF
organization = "#{settings.cert_organisation}"
unit = "#{settings.cert_unit}"
locality = "#{settings.cert_locality}"
state = "#{settings.cert_state}"
country = "#{settings.cert_country}"
cn = #{settings.ca_fqdn}
serial = #{settings.cert_serial}
expiration_days = #{settings.cert_expiration_days}
ca
cert_signing_key
EOF

  cert_temp =<<EOF
organization = "#{settings.cert_organisation}"
unit = "#{settings.cert_unit}"
locality = "#{settings.cert_locality}"
state = "#{settings.cert_state}"
country = "#{settings.cert_country}"
cn = #{settings.server_fqdn}
serial = #{settings.cert_serial}
expiration_days = #{settings.cert_expiration_days}
EOF

      File.open("#{tempdir}/ca-cert.temp", "w") {|file|
        file.write(ca_temp)
      }
      
      File.open("#{tempdir}/cert.temp", "w") {|file|
        file.write(cert_temp)
      }
      
      if !File.exists?("/etc/ssl/private/slapd-ca-key.pem") || !File.exists?("/etc/ssl/certs/slapd-ca-cert.pem")
        `certtool --generate-privkey --outfile #{tempdir}/slapd-ca-key.pem`
        `certtool --generate-self-signed --load-privkey #{tempdir}/slapd-ca-key.pem --outfile #{tempdir}/slapd-ca-cert.pem --template #{tempdir}/ca-cert.temp`
        
        `install -o root -g root -m 644 #{tempdir}/slapd-ca-cert.pem /etc/ssl/certs/slapd-ca-cert.pem`
        `install -o root -g root -m 600 #{tempdir}/slapd-ca-key.pem /etc/ssl/private/slapd-ca-key.pem`

        #    puts `ls -l #{tempdir}/slapd-ca-cert.pem #{tempdir}/slapd-ca-key.pem /etc/ssl/certs/slapd-ca-cert.pem /etc/ssl/private/slapd-ca-key.pem`
      else
        puts "CA certificate exists in /etc/ssl/certs/slapd-ca-cert.pem and /etc/ssl/private/slapd-ca-key.pem..."
      end
      
      if !File.exists?("/etc/ssl/certs/slapd-server.crt") || !File.exists?("/etc/ssl/certs/slapd-server.key")
        `certtool --generate-privkey --outfile #{tempdir}/slapd-server.key`
        `certtool --generate-certificate --load-privkey #{tempdir}/slapd-server.key --outfile #{tempdir}/slapd-server.crt --load-ca-certificate /etc/ssl/certs/slapd-ca-cert.pem --load-ca-privkey /etc/ssl/private/slapd-ca-key.pem --template #{tempdir}/cert.temp`
        
        `install -D -o openldap -g openldap -m 600 #{tempdir}/slapd-server.crt /etc/ssl/certs/slapd-server.crt`
        `install -D -o openldap -g openldap -m 600 #{tempdir}/slapd-server.key /etc/ssl/certs/slapd-server.key`
        
        #    puts `ls -l #{tempdir}/slapd-server.crt /etc/ssl/certs/slapd-server.crt #{tempdir}/slapd-server.key /etc/ssl/certs/slapd-server.key #{tempdir}/cert.temp #{tempdir}/slapd-ca-cert.pem`
      else
        puts "Server certificate exists in /etc/ssl/certs/slapd-server.{crt|key}..."
      end
      
      ldif =<<EOF
dn: cn=config
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ssl/certs/slapd-ca-cert.pem
-
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ssl/certs/slapd-server.crt
-
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ssl/certs/slapd-server.key
EOF

      `echo "#{ldif}" | ldapmodify -c -Y EXTERNAL -H ldapi:/// 2> /dev/null`
    end
    
    def self.setup_sasl(dbsettings)
      realm = dbsettings.kerberos_realm
      suffix = dbsettings.suffix

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcAuthzRegexp', ["\"uid=([^,]*),cn=#{realm},cn=gssapi,cn=auth\" \"uid=$1,ou=People,#{suffix}\"", "\"uid=(.*?)@#{realm},cn=gssapi,cn=auth\" \"uid=$1,ou=People,#{suffix}\""]),
             ]

      puts "Adding SASL mappings for authentication:"
      
      edit_entry(dbsettings, "cn=config", ldif)
    end

    def self.setup_database_acls(dbsettings)
      suffix = dbsettings.suffix
      samba_domain = dbsettings.samba_domain

      ldapdump = `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b cn=config "(&(objectClass=olcDatabaseConfig)(olcSuffix=#{suffix}))" olcSuffix 2>/dev/null | grep dn:`

      if ! ldapdump.empty?
        if /dn: (.*?)\n/.match(ldapdump)
          database = $1

          puts "database: #{database}"

          ldif =<<EOF
dn: #{database}
changetype: modify
delete: olcAccess
EOF

          `echo "#{ldif}" | ldapmodify -Q -c -Y EXTERNAL -H ldapi:/// 2> /dev/null`

          puavo_user_dn = "uid=puavo,o=puavo"
          admin_set = "set=\"this/puavoSchool/puavoSchoolAdmin* | [#{suffix}]/owner* & user\""
          all_admins_set = "set=\"[ldap:///ou=Groups,#{suffix}??one?(objectClass=puavoSchool)]/puavoSchoolAdmin* | [#{suffix}]/owner* & user\""
          super_acl = "by dn=\"uid=admin,o=puavo\" manage"

          num = 0

          # The ACLs are still under work and do not protect all the entries as they should
          #
          # The idea behind the rules is this:
          # - RootDN (uid=admin,o=Puavo by default) is used to setup the database and structure
          # - Organisation has owners that can modify schools, groups, roles and users in all schools
          # - Schools have admins that can modify groups, roles and users under their schools
          # - Puavo uses uid=puavo,o=Puavo to search for bind DNs using the uid
          # - Hosts have entries under ou=Hosts that have access to NSS information
          # - Kerberos KDC uses uid=kdc,ou=System Accounts to read data under ou=Kerberos Realms
          # - Kerberos kadmin user uid=kadmin,ou=System Accounts to modify data under ou=Kerberos Realms
          # - Automount information is accessible to all by default (maybe some IP based restrictions?)
          # - Samba entry sambaDomainName=DOMAIN is accessible to all organisation owners, schools admins and special samba user uid=samba,ou=System Accounts
          # - Access to root entry is allowed if any of the above gives access, no anonymous access is allowed

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcAccess', 
                           [
                            "{0}to dn.exact=\"ou=Roles,#{suffix}\" attrs=\"entry,ou\" #{super_acl} by #{all_admins_set} read",
                            "{1}to dn.exact=\"ou=Roles,#{suffix}\" attrs=\"children\" #{super_acl} by #{all_admins_set} write",
                            "{2}to dn.subtree=\"ou=Roles,#{suffix}\" #{super_acl} by #{admin_set} write",
                            "{3}to dn.subtree=\"ou=Automount,#{suffix}\" #{super_acl} by * +rscxd",
                            "{4}to dn.subtree=\"ou=Kerberos Realms,#{suffix}\" #{super_acl} by dn=\"uid=kadmin,ou=System Accounts,#{suffix}\" write by dn=\"uid=kdc,ou=System Accounts,#{suffix}\" read",
                            "{5}to dn.subtree=\"ou=Hosts,#{suffix}\" #{super_acl} by dn=\"uid=samba,ou=System Accounts,#{suffix}\" +wrscxd",
                            "{6}to dn.exact=\"ou=People,#{suffix}\" attrs=\"entry,ou\" #{super_acl} by users read",
                            "{7}to dn.exact=\"ou=People,#{suffix}\" attrs=\"children\" #{super_acl} by #{all_admins_set} write by dn.exact=\"#{puavo_user_dn}\" read",
                            "{8}to dn.subtree=\"ou=People,#{suffix}\" attrs=\"userPassword,shadowLastChange\" #{super_acl} by #{admin_set} write by self write by anonymous auth",
                            "{9}to dn.subtree=\"ou=People,#{suffix}\" attrs=\"entry,uid,puavoId,eduPersonPrincipalName,objectClass\" #{super_acl} by #{admin_set} write by dn=\"#{puavo_user_dn}\" read",
                            "{10}to dn.subtree=\"ou=People,#{suffix}\" #{super_acl} by #{admin_set} write by dn.subtree=\"ou=Hosts,#{suffix}\" read",
                            "{11}to dn.exact=\"ou=Groups,#{suffix}\" attrs=\"entry,ou\" #{super_acl} by #{all_admins_set} read by dn.subtree=\"ou=System Accounts,#{suffix}\" read by dn.subtree=\"ou=Hosts,#{suffix}\" read",
                            "{12}to dn.exact=\"ou=Groups,#{suffix}\" attrs=\"children\" #{super_acl} by set=\"[ldap:///ou=Groups,#{suffix}??one?(objectClass=puavoSchool)]/puavoSchoolAdmin* & user | [#{suffix}]/owner* & user\" write by dn.subtree=\"ou=System Accounts,#{suffix}\" read by dn.subtree=\"ou=Hosts,#{suffix}\" read",
                            "{13}to dn.subtree=\"ou=Groups,#{suffix}\" filter=(objectClass=puavoEduGroup) attrs=\"gidNumber,cn,puavoId,objectClass\" #{super_acl} by #{admin_set} write by dn.subtree=\"ou=Hosts,#{suffix}\" +rscxd",
                            "{14}to dn.subtree=\"ou=Groups,#{suffix}\" filter=(objectClass=puavoSchool) attrs=\"gidNumber,cn,puavoId,objectClass\" #{super_acl} by set=\"[#{suffix}]/owner* & user\" +azrwsc by set=\"this/puavoSchoolAdmin* & user\" +rwsc by dn.subtree=\"ou=Hosts,#{suffix}\" +rscd break",
                            "{15}to dn.subtree=\"ou=Groups,#{suffix}\" filter=(objectClass=puavoEduGroup) #{super_acl} by #{admin_set} write",
                            "{16}to dn.subtree=\"ou=Groups,#{suffix}\" filter=(objectClass=puavoSchool) attrs=\"member,memberUid\" #{super_acl} by set=\"this/puavoSchoolAdmin* | [#{suffix}]/owner* & user\" write break",
                            "{17}to dn.subtree=\"ou=Groups,#{suffix}\" filter=(objectClass=puavoSchool) #{super_acl} by set=\"[#{suffix}]/owner* & user\" write by set=\"this/puavoSchoolAdmin* & user\" +rscxd",
                            "{18}to dn.exact=\"sambaDomainName=#{samba_domain},#{suffix}\" attrs=\"sambaSID,sambaDomainName,sambaNextUserRid\" #{super_acl} by dn=\"uid=samba,ou=System Accounts,#{suffix}\" write by set=\"[ldap:///ou=Groups,#{suffix}??one?(objectClass=puavoSchool)]/puavoSchoolAdmin* | [#{suffix}]/owner* & user\" write",
                            "{19}to dn.exact=\"sambaDomainName=#{samba_domain},#{suffix}\" #{super_acl} by #{admin_set} write by dn=\"uid=samba,ou=System Accounts,#{suffix}\" write by set=\"[ldap:///ou=Groups,#{suffix}??one?(objectClass=puavoSchool)]/puavoSchoolAdmin* | [#{suffix}]/owner* & user\" read",
                            "{20}to dn.subtree=\"ou=System Accounts,#{suffix}\" attrs=\"userPassword\" #{super_acl} by anonymous auth",
                            "{21}to dn=\"#{suffix}\" #{super_acl} by dn.subtree=\"ou=System Accounts,#{suffix}\" +rscxd by set=\"[ldap:///ou=Groups,#{suffix}??one?(objectClass=puavoSchool)]/puavoSchoolAdmin* | [#{suffix}]/owner* & user\" read by dn.exact=\"#{puavo_user_dn}\" read by * +xd"
                           ])]

          puts "Initializing acls for #{suffix}...\n"
          edit_entry(dbsettings, "#{database}", ldif)
        end
      end
    end

    def self.setup_puavo_database_acls(dbsettings)
      suffix = dbsettings.suffix
      samba_domain = dbsettings.samba_domain

      ldapdump = `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -b cn=config "(&(objectClass=olcDatabaseConfig)(olcSuffix=#{suffix}))" olcSuffix 2>/dev/null | grep dn:`

      if ! ldapdump.empty?
        if /dn: (.*?)\n/.match(ldapdump)
          database = $1

          puts "database: #{database}"

          ldif =<<EOF
dn: #{database}
changetype: modify
delete: olcAccess
EOF

          `echo "#{ldif}" | ldapmodify -Q -c -Y EXTERNAL -H ldapi:/// 2> /dev/null`

          ldif = [
                  LDAP.mod(LDAP::LDAP_MOD_ADD, 'olcAccess', 
                           ["{0}to attrs=userPassword by anonymous auth",
                            "{1}to dn.exact=\"cn=idPool,o=Puavo\" attrs=\"puavoNextGidNumber,puavoNextUidNumber,puavoNextId\" by dn.exact=\"uid=puavo,o=Puavo\" write",
                            "{2}to dn.subtree=\"o=Puavo\" by dn.exact=\"uid=puavo,o=Puavo\" read"
                           ])]

          puts "Initializing acls for #{suffix}...\n"
          edit_entry(dbsettings, "#{database}", ldif)
        end
      end
    end

    def self.check_schemas(schemas)
      installed_schemas = []
      missing_schemas = []

      schemas.each do |schema|
        ldapdump = `ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config cn=*#{schema} 2>/dev/null | grep dn:`

        if ldapdump.empty?
          missing_schemas << schema
        else
          installed_schemas << schema
        end
      end

      return { :installed_schemas => installed_schemas,
        :missing_schemas => missing_schemas }
    end

    def self.check_modules(modules)
      installed_modules = []
      missing_modules = []

      modules.each do |mod|
        ldapdump = `ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(&(cn=module*)(olcModuleLoad=back_hdb))" #{mod} 2>/dev/null | grep dn:`
      
        if ldapdump.empty?
          missing_modules << mod
        else
          installed_modules << mod
        end
      end

      return { :installed_modules => installed_modules,
        :missing_modules => missing_modules }
    end
    
    def self.list_configured_databases
      databases = []

#      ldapdump = `ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcDatabaseConfig)" olcSuffix 2>/dev/null | grep olcSuffix:`
#      ldapdump = `ldapsearch -x -D uid=admin,o=puavo -w admin -s base -b "" "(objectClass=*)" namingContexts | grep namingContexts:`
      ldapdump = `ldapsearch -Q -Y EXTERNAL -H ldapi:/// -s base -b "" "(objectClass=*)" namingContexts 2>/dev/null | grep namingContexts:`

      if ldapdump.empty?
      else
        ldapdump.split("\n").each do |olcSuffix|
          /namingContexts: (.*)/.match(olcSuffix)
          suffix = $1

          databases << suffix

          path = "/var/lib/ldap/#{suffix}"
          
          if File.directory?(path)
#            puts "  DB directory #{path} exists"
          end
        end
      end

      return databases
    end

    def self.check_certificates
      result = true

      ldapdump = `ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(cn=config)" olcTLSCACertificateFile olcTLSCertificateFile olcTLSCertificateKeyFile 2>/dev/null`
      
      if /olcTLSCACertificateFile: (.*?)\n/.match(ldapdump)
        ca_cert_file = $1
      end
      
      if /olcTLSCertificateFile: (.*?)\n/.match(ldapdump)
        cert_file = $1
      end
      
      if /olcTLSCertificateKeyFile: (.*?)\n/.match(ldapdump)
        cert_key_file = $1
      end
      
      if !ca_cert_file || ca_cert_file.empty?
        puts "* ERROR: TLSCACertificateFile not defined!"
        result = false
      else
        if !File.exists?(ca_cert_file)
          puts "* ERROR: TLSCACertificateFile #{ca_cert_file} defined, but missing!"
          result = false
        else
          cacertdump = `certtool --certificate-info --infile #{ca_cert_file}`
          
          if /Subject: .*,CN=(.*?)\n/.match(cacertdump)
            cacert_hostname = $1
            
            begin
              cacert_host_ip = IPSocket.getaddress(cacert_hostname)
            rescue => e
              puts "* ERROR: CA cert hostname #{cacert_hostname} not found!"
              result = false
            end
          else
            puts "* ERROR: CA certificate #{ca_cert_file} does not have hostname!"
            result = false
          end
        end
      end
      
      if !cert_file || cert_file.empty?
        puts "* ERROR: TLSCertificateFile not defined!"
        result = false
      else
        if !File.exists?(cert_file)
          puts "* ERROR: TLSCertificateFile #{cert_file} defined, but missing!"
          result = false
        else
          certdump = `certtool --certificate-info --infile #{cert_file}`
          
          if /Subject: .*,CN=(.*?)\n/.match(certdump)
            cert_hostname = $1
            
            begin
              cert_host_ip = IPSocket.getaddress(cert_hostname)
            rescue => e
              puts "* ERROR: Cert hostname #{cert_hostname} not found!"
              result = false
            end
          else
            puts "* ERROR: Certificate #{cert_file} does not have hostname!"
            results = false
          end
        end
      end
      
      if !cert_key_file || cert_key_file.empty?
        puts "* ERROR: TLSCACertificateKeyFile not defined!"
        result = false
      else
        if !File.exists?(cert_key_file)
          puts "* ERROR: TLSCertificateKeyFile #{cert_key_file} defined, but missing!"
          result = false
        else
        end
      end
      
      #  puts "cert: #{ldapdump}"
      
      hostname = Socket.gethostbyname(Socket.gethostname).first
      
      begin
        host_ip = IPSocket.getaddress(hostname)
      rescue => e
        puts "* ERROR: IP for #{cacert_hostname} not found!"
        result = false
      end
      
      if result
        puts "SSL/TLS certificate configuration OK:"
        puts "* TLSCACertificateFile #{ca_cert_file}"
        puts "* TLSCertificateFile #{cert_file}"
        puts "* TLSCertificateKeyFile #{cert_key_file}"
        puts "* CA cert hostname: #{cacert_hostname} (#{cacert_host_ip})"
        puts "* Cert hostname: #{cert_hostname} (#{cert_host_ip})"
        puts "* Server hostname: #{hostname} (#{host_ip})"
      end
      
      return result
    end

    def check_ldap_client_conf
      content = ""

      puts "Checking ldap client configuration in /etc/ldap/ldap.conf:"
      
      f = File.open("/etc/ldap/ldap.conf", "r") 
      f.each_line do |line|
        if ! /^\#/.match(line)
          content += line
        end
      end
      
      if /BASE\s*(.*?)\n/.match(content)
        suffix = $1
        
        puts "* BASE: #{suffix}"
      else
        puts "* ERROR: BASE not defined in /etc/ldap/ldap.conf"
        result = false
      end
      
      #  puts "LDAP client configuration (/etc/ldap/ldap.conf):"
      
      if /URI\s*(.*?)\n/.match(content)
        uris = $1
        
        uris.split.each do |uri|
          if /ldap[s]*:\/\/(.*?)[$\/]/.match(uri)
            hostname = $1
            
            begin
              ip = IPSocket.getaddress(hostname)
              puts "* URI: #{uri} OK (IP: #{ip})"
            rescue => e
              puts "* ERROR: hostname #{hostname} in URI #{uri} not found!"
              result = false
            end
            
            if /ldaps:\/\/(.*?)[$\/]/.match(uri)
              use_tls = false
              port = 636
              method = "SSL"
            else
              use_tls = true
              port = 389
              method = "StartTLS"
            end
            
            begin
              conn = LDAP::SSLConn.new(host=hostname, port=port, use_tls)
              conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
              conn.search(suffix, LDAP::LDAP_SCOPE_SUBTREE, "(objectclass=*)"){|e|}
              
              puts "* Connection to #{hostname}:#{port} with #{method} OK"
            rescue => e
              puts e.inspect
              puts "* ERROR: Failed to connect to #{uri} using #{method}"
            end
          end
        end
      end
      
      if /TLS_CACERT\s*(.*?)\n/.match(content)
        ca_cert_file = $1
        
        puts "* CA certificate file: #{ca_cert_file}"
        
        cacertdump = `certtool --certificate-info --infile #{ca_cert_file}`
        
        if /Subject: .*,CN=(.*?)\n/.match(cacertdump)
          cacert_hostname = $1
          
          puts "* CA certificate has hostname #{cacert_hostname}"
        end
      else
        puts "* ERROR: CA certificate file not defined (TLS_CACERT)!"
      end
    end

    def self.initialize_autofs(dbsettings)
      suffix = dbsettings.suffix

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['top', 'automountMap']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'ou', ["auto.master"]),
             ]
  
      add_entry_if_missing(dbsettings, "ou=auto.master,ou=Automount,#{suffix}", ldif)
  
      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['top', 'automount']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'cn', ["/home"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'automountInformation', ["ldap:ou=auto.home,ou=Automount,#{suffix} rsize=8192,wsize=8192"])
         ]
      
      add_entry_if_missing(dbsettings, "cn=/home,ou=auto.master,ou=Automount,#{suffix}", ldif)

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectclass', ['top', 'automountMap']),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'ou', ["auto.home"]),
             ]
      
      add_entry_if_missing(dbsettings, "ou=auto.home,ou=Automount,#{suffix}", ldif)
    end

    def self.find_samba_sid(dbsettings)
      conn = LDAP::Conn.new(host='127.0.0.1', port=389)
      conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
          
      if dbsettings.rootdn and dbsettings.rootpw
        rootdn = dbsettings.rootdn
        rootpw = dbsettings.rootpw
      else
        rootdn = dbsettings.server.connect_dn
        rootpw = dbsettings.server.connect_password
      end

      dns = []

      conn.bind(rootdn, rootpw) do
        begin
          begin
            conn.search(dbsettings.suffix, LDAP::LDAP_SCOPE_SUBTREE, "(sambaDomainName=#{dbsettings.samba_domain})") {|e|
              return e.vals('sambaSID')[0]
            }
          rescue LDAP::ResultError
          end
        end
      end
    end

    def self.find_next_puavo_id(dbsettings)
      conn = LDAP::Conn.new(host='127.0.0.1', port=389)
      conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
          
      if dbsettings.rootdn and dbsettings.rootpw
        rootdn = dbsettings.rootdn
        rootpw = dbsettings.rootpw
      else
        rootdn = dbsettings.server.connect_dn
        rootpw = dbsettings.server.connect_password
      end

      dns = []

      conn.bind(rootdn, rootpw) do
        begin
          begin
            conn.search(dbsettings.server.id_pool, LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=puavoIdPool)") {|e|
              id = e.vals('puavoNextId')[0]
              
              ldif = [
                      LDAP.mod(LDAP::LDAP_MOD_REPLACE, 'puavoNextId', ["#{id+1}"])
                     ]

              conn.modify(dbsettings.server.id_pool, ldif)

              return id
            }
          rescue LDAP::ResultError
          end
        end
      end
    end

    def self.insert_samba_data(dbsettings)
      suffix = dbsettings.suffix

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectClass', ["sambaDomain"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaDomainName', [dbsettings.samba_domain]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaSID', [dbsettings.samba_sid]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaAlgorithmicRidBase', ["1000"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaNextUserRid', ["1000"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaMinPwdLength', ["7"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaPwdHistoryLength', ["0"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaLogonToChgPwd', ["0"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaMaxPwdAge', ["-1"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaMinPwdAge', ["0"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaLockoutDuration', ["30"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaLockoutObservationWindow', ["30"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaLockoutThreshold', ["0"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaForceLogoff', ["-1"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaRefuseMachinePwdChange', ["0"]),
             ]

      add_entry_if_missing(dbsettings, "sambaDomainName=#{dbsettings.samba_domain},#{suffix}", ldif)

      groups = [
                [512, 'Domain Admins', 'Netbios Domain Administrators'],
                [513, 'Domain Users', 'Netbios Domain Users'],
                [514, 'Domain Guests', 'Netbios Domain Guest Users'],
                [550, 'Print Operators', 'Netbios Domain Print Operators'],
                [551, 'Backup Operators', 'Netbios Domain Members can bypass file security to back up files'],
                [552, 'Replicators', 'Netbios Domain Supports file replication in a sambaDomainName'],
                [553, 'Domain Computers', 'Netbios Domain Computers accounts'],
                [533, 'Administrators', 'Netbios Domain Members can fully administer the computer/sambaDomainName'],
                [545, 'Users', 'Netbios Domain Ordinary users'],
                [546, 'Guests', 'Netbios Domain Users granted guest access to the computer/sambaDomainName'],
                [547, 'Power Users', 'Netbios Domain Members can share directories and printers'],
                [548, 'Account Operators', 'Netbios Domain Users to manipulate users accounts'],
                [549, 'Server Operators', 'Netbios Domain Server Operators']
               ]

      groups.each {|data|
#        puts "TESTI: #{data.inspect}"

        ldif = [
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectClass', ["top","posixGroup", "sambaGroupMapping"]),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaSID', ["#{dbsettings.samba_sid}-#{data[0]}"]),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaGroupType', ["2"]),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'displayName', ["#{data[1]}"]),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'description', ["#{data[2]}"]),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'gidNumber', ["#{data[0]}"]),
                LDAP.mod(LDAP::LDAP_MOD_ADD, 'cn', ["#{data[1]}"])
               ]

        add_entry_if_missing(dbsettings, "cn=#{data[1]},ou=Groups,#{suffix}", ldif)
      }
    end

    def self.add_computer(dbsettings, computer)
      puavoId = find_next_puavo_id(dbsettings)

      ldif = [
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'objectClass', ["sambaDomain"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'puavoId', ["#{puavoId}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'cn', ["#{computer.name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sn', ["#{computer.name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'uid', ["#{computer.name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'displayName', ["#{computer.name.upcase}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'uidNumber', ["#{computer.name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'gidNumber', ["#{computer.name}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaSID', ["#{dbsettings.samba_sid}-#{puavoId}"]),
              LDAP.mod(LDAP::LDAP_MOD_ADD, 'sambaPrimaryGroupSID', ["#{dbsettings.samba_sid}-515"]),
             ]

      add_entry_if_missing(dbsettings,"puavoId=#{puavoId},ou=Hosts,#{suffix}", ldif)
    end

    def self.setup_kdc_kadmin(settings, default_realm, kadmind_ports)
      rootdn = settings.connect_dn
      rootpw = settings.connect_password

      puts "* Creating kerberos configuration in /etc/krb5.conf for:"

      acl = ""
      realms = ""
      dbmodules = ""
      domain_realm = ""
      kdc_conf_realms = ""
      kdc_realms_list = ""
      kadmind_cmds = ""

      list_configured_databases.each do |db_suffix|
        if db_suffix !~ /o=puavo/i
          tmp_dbinfo = `ldapsearch -x -D #{rootdn} -w #{rootpw} -s base -b #{db_suffix}`

          if /o: (.*)\n/.match(tmp_dbinfo)
            dbname = $1

            if /puavoKerberosRealm: (.*)\n/.match(tmp_dbinfo)
              kerberos_realm = $1
            
              puts "  + #{dbname} (#{kerberos_realm})"

              kdc_realms_list += " -r #{kerberos_realm}"

              dbmodules +=<<EOF
  ldap_#{dbname} = {
               db_library = kldap
               ldap_kerberos_container_dn = ou=Kerberos Realms,#{db_suffix}
               ldap_kdc_dn = uid=kdc,ou=System Accounts,#{db_suffix}
               ldap_kadmind_dn = uid=kadmin,ou=System Accounts,#{db_suffix}
               ldap_service_password_file = /etc/krb5.secrets
               ldap_servers = ldap://127.0.0.1
               ldap_conns_per_server = 10
        }

EOF

              puts "    * Writing kadmind ACL rules in /etc/krb5kdc/kadm5.acl.#{dbname} ..."

              File.open("/etc/krb5kdc/kadm5.acl.#{dbname}", "w") {|file|
                file.write("smbkrb5pwd/*@#{dbname.upcase}\t*\t*@#{dbname.upcase}\n")
              }

              # MIT kadmind does not support multiple realms in a single instance, so
              # we need to run one instance per realm
              #
              # For now just configure the ports in sequence as they are configured

              if kadmind_ports[kerberos_realm]
                kadmind_port_colon = ":#{kadmind_ports[kerberos_realm]}"
                kadmind_port = "#{kadmind_ports[kerberos_realm]}"
              else
                kadmind_port = "749"
                kadmind_port_colon = ""
              end

              realms +=<<EOF
  #{kerberos_realm} = {
             kdc = kerberos.#{dbname}
             admin_server = kerberos.#{dbname}#{kadmind_port_colon}
             master_kdc = kerberos.#{dbname}
             default_domain = #{dbname}
             database_module = ldap_#{dbname}
  }

EOF

              kadmind_cmds += "kadmind -r #{kerberos_realm} -port #{kadmind_port}\n"

              domain_realm +=<<EOF
         .#{dbname} = #{kerberos_realm}
         #{dbname} = #{kerberos_realm}
EOF

              kdc_conf_realms +=<<EOF
      #{kerberos_realm} = {
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab.#{dbname}
        acl_file = /etc/krb5kdc/kadm5.acl.#{dbname}
        key_stash_file = /etc/krb5kdc/stash.#{dbname}
        max_life = 5d 0h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        supported_enctypes = aes256-cts:normal arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3
        default_principal_flags = +preauth
        kadmind_port = #{kadmind_port}
      }
EOF
            end
          end
        end
      end

      krb5_conf=<<EOF
[libdefaults]
        default_realm = #{default_realm}
        default_tgs_enctypes = des3-hmac-sha1 des-cbc-crc
        default_tkt_enctypes = des3-hmac-sha1 des-cbc-crc
        allow_weak_crypto = true

[realms]
#{realms}

[domain_realm]
#{domain_realm}

[logging]
        kdc = FILE:/var/log/kdc.log
        admin_server = FILE:/var/log/kadm5.log

[dbmodules]
#{dbmodules}
EOF

      kdc_conf =<<EOF
[kdcdefaults]
    kdc_ports = 750,88

[realms]
#{kdc_conf_realms}
EOF

      File.open("/etc/krb5.conf", "w") {|file|
        file.write(krb5_conf)
      }

      puts "* Writing /etc/krb5kdc/kdc.conf ..."

      File.open("/etc/krb5kdc/kdc.conf", "w") {|file|
        file.write(kdc_conf)
      }

      puts "* Writing realms to /etc/default/krb5-kdc ..."

      File.open("/etc/default/krb5-kdc", "w") {|file|
        file.write("DAEMON_ARGS=\"#{kdc_realms_list}\"")
      }

      puts "* Start kadmind daemons with the following commands:"
      puts "------------------------------------------------------------------"
      puts kadmind_cmds
      puts "------------------------------------------------------------------"      
    end

    def self.setup_kerberos(dbsettings)
      domain = dbsettings.domain
      kerberos_realm = dbsettings.kerberos_realm
      suffix = dbsettings.suffix
      kdc_ldapdn = dbsettings.kdc_ldapdn
      kdc_ldappw = dbsettings.kdc_ldappw
      kadmin_ldapdn = dbsettings.kadmin_ldapdn
      kadmin_ldappw = dbsettings.kadmin_ldappw
      kerberos_masterpw = dbsettings.kerberos_masterpw

      rootdn = dbsettings.server.connect_dn
      rootpw = dbsettings.server.connect_password

      puts "Initializing kerberos in ldap:"

      puts "* Stopping kerberos server..."
      `/etc/init.d/krb5-kdc stop`
      `/etc/init.d/krb5-admin-server stop`
      `/etc/init.d/nscd stop`

#      puts "echo \"#{kerberos_masterpw}\\n#{kerberos_masterpw}\\n\" | /usr/sbin/kdb5_ldap_util -D #{rootdn} create -subtrees #{suffix} -s -H ldap://localhost -r #{kerberos_realm} -w #{rootpw} 2>/dev/null`"
#      puts "echo \"#{kerberos_ldappw}\\n#{kerberos_ldappw}\\n\" | /usr/sbin/kdb5_ldap_util stashsrvpw -f /etc/krb5.secrets #{kerberos_ldapdn} 2>/dev/null"

      puts "* Creating kerberos entries in ldap..."

      `echo "#{kerberos_masterpw}\\n#{kerberos_masterpw}\\n" | /usr/sbin/kdb5_ldap_util -D "#{rootdn}" create -subtrees "#{suffix}" -s -sf /etc/krb5kdc/stash.#{domain} -H ldap://localhost -r "#{kerberos_realm}" -w #{rootpw} 2>/dev/null`
      `echo "#{kdc_ldappw}\\n#{kdc_ldappw}\\n" | /usr/sbin/kdb5_ldap_util stashsrvpw -f /etc/krb5.secrets "#{kdc_ldapdn}" -w #{kdc_ldappw} 2>/dev/null`
      `echo "#{kadmin_ldappw}\\n#{kadmin_ldappw}\\n" | /usr/sbin/kdb5_ldap_util stashsrvpw -f /etc/krb5.secrets "#{kadmin_ldapdn}" -w #{kadmin_ldappw} 2>/dev/null`

      `/usr/sbin/kdb5_ldap_util -D "uid=kadmin,ou=System Accounts,#{suffix}" -H ldap://localhost -w #{kadmin_ldappw} modify -maxrenewlife "6 day" -maxtktlife "144 hours" 2>/dev/null`

      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "addprinc -randkey ldap/ldap.#{domain}@#{kerberos_realm}" 2>/dev/null`

      exists=`klist -k -t /etc/ldap/slapd.keytab 2>/dev/null | grep "ldap/ldap.#{domain}@#{kerberos_realm}"`

      if exists.empty?
        #        `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktremove -k /etc/ldap/slapd.keytab ldap/ldap.#{domain}@#{kerberos_realm}" 2>/dev/null`
        `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktadd -e des-cbc-crc:normal -k /etc/ldap/slapd.keytab ldap/ldap.#{domain}@#{kerberos_realm}" 2>/dev/null`
      else
#        puts "SKIP"
      end

      fqdn = `hostname -f`.gsub(/\n/,'')

      puts "* Creating principal for smbkrb5pwd/#{fqdn}@#{kerberos_realm} and storing it in /etc/ldap/slapd.d/openldap-krb5.keytab..."

      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "addprinc -randkey smbkrb5pwd/#{fqdn}@#{kerberos_realm}" 2>/dev/null`
      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "addprinc -randkey kadmin/#{fqdn}@#{kerberos_realm}" 2>/dev/null`
      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktremove -k /etc/ldap/slapd.d/openldap-krb5.keytab smbkrb5pwd/#{fqdn}@#{kerberos_realm}" 2>/dev/null`
      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktadd -e des-cbc-crc:normal -k /etc/ldap/slapd.d/openldap-krb5.keytab smbkrb5pwd/#{fqdn}@#{kerberos_realm}"`

      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktremove -k /etc/krb5kdc/kadm5.keytab.#{domain} kadmin/admin@#{kerberos_realm}" 2>/dev/null`
      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktremove -k /etc/krb5kdc/kadm5.keytab.#{domain} kadmin/changepw@#{kerberos_realm}" 2>/dev/null`
      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktadd -e des-cbc-crc:normal -k /etc/krb5kdc/kadm5.keytab.#{domain} kadmin/admin@#{kerberos_realm}" 2>/dev/null`
      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktadd -e des-cbc-crc:normal -k /etc/krb5kdc/kadm5.keytab.#{domain} kadmin/changepw@#{kerberos_realm}" 2>/dev/null`
      `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "ktadd -e des-cbc-crc:normal -k /etc/krb5kdc/kadm5.keytab.#{domain} kadmin/#{fqdn}@#{kerberos_realm}" 2>/dev/null`

      `chown openldap.openldap /etc/ldap/slapd.keytab /etc/ldap/slapd.d/openldap-krb5.keytab`
      `chmod 0600 /etc/ldap/slapd.keytab`

      puts "* Starting kerberos server..."

      `/etc/init.d/krb5-kdc restart`
      `/etc/init.d/krb5-admin-server restart`
    end

    # Method to create principals for different services supporting
    # kerberos.
    #
    # The list of possible services has been mostly copied from
    # Launchpad:
    #
    # https://wiki.ubuntu.com/NetworkAuthentication/KerberizeServices
    #
    # openssh                  GSSAPI   host/fqdn@REALM
    # openldap                 SASL     ldap/fqdn@REALM
    # samba (as a cifs server)          cifs/fqdn@REALM host/fqdn@REALM
    # postfix                  SASL     smtp/fqdn@REALM
    # exim4                    SASL     
    # dovecot                  GSSAPI   imap/fqdn@REALM pop/fqdn@REALM
    # cupsys                   GSSAPI   IPP/fqdn@REALM
    # postgresql               GSSAPI   postgres/fqdn@REALM
    # mysql                    Not available
    # apache2                  via mod-auth-krb5 HTTP/fqdn@REALM HTTP/short_fqdn@REALM
    # freeradius               freeradius-krb5 module
    # ipsec-tools (racoon)     GSSAPI   
    # openvpn
    # pptpd
    # vsftpd
    # virt-manager/libvirt
    # nfs                      GSSAPI   nfs/fqdn@REALM
    # pam                      libpam-krb5 pam/fqdn@REALM   (to be done!)
    #
    # On client machines keytab files will be placed in locations that
    # are allowed by AppArmor:
    #
    # /etc/...

    def self.add_host(dbsettings, fqdn)
      ["host",
       "ldap",
       "cifs",
       "IPP",
       "HTTP",
       "nfs",
       "pam"].each do |service|
        puts "* #{service}/#{fqdn}@#{dbsettings.kerberos_realm}"

        `/usr/sbin/kadmin.local -r #{kerberos_realm} -q "addprinc -randkey #{service}/#{fqdn}@#{dbsettings.kerberos_realm}" 2>/dev/null`
      end
    end
  end
end
