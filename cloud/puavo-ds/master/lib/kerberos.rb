class KerberosSettings
  def initialize(organisations)
    @organisations = organisations
  end

  def kdc_conf
    if @kdc_conf
      return @kdc_conf
    else
      kdc_conf_erb = File.read("templates/kdc.conf.erb")
      kdc_conf = ERB.new(kdc_conf_erb, 0, "%<>")

      @kdc_conf = kdc_conf.result(getBinding)

      return @kdc_conf
    end
  end

  def krb5_conf
    if @krb5_conf
      return @krb5_conf
    else
      krb5_conf_erb = File.read("templates/krb5.conf.erb")
      krb5_conf = ERB.new(krb5_conf_erb, 0, "%<>")

      @krb5_conf = krb5_conf.result(getBinding)

      return @krb5_conf
    end
  end

  def kadm5_acl
    if @kadm5_acl
      return @kadm5_acl
    else
      kadm5_acl_erb = File.read("templates/kadm5.acl.erb")
      kadm5_acl = ERB.new(kadm5_acl_erb, 0, "%<>")

      @kadm5_acl = kadm5_acl.result(getBinding)

      return @kadm5_acl
    end
  end

  def daemon_args
    return "DAEMON_ARGS=\"" + @organisations.collect! {|org| "-r " + org['realm']}.join(" ") + "\""
  end

  def getBinding
    return binding()
  end
end
  
class KerberosRealm
  require "erb"
  require "yaml"
  require 'tempfile'

  attr_accessor :ldap_server, :realm, :masterpw, :suffix, :domain

  def initialize(args)
    self.ldap_server = args[:ldap_server]
    self.realm = args[:realm]
    self.masterpw = args[:masterpw]
    self.suffix = args[:suffix]
    self.domain = args[:domain]
  end

  def create_ldap_tree
    puts self.masterpw

    KerberosRealm.create_kerberos_configuration(ldap_server)

    puts "echo \"#{self.masterpw}\\n#{self.masterpw}\\n\" | /usr/sbin/kdb5_ldap_util -D #{ldap_server['bind_dn']} create -k aes256-cts-hmac-sha1-96 -subtrees \"#{self.suffix}\" -s -sf /etc/krb5kdc/stash.#{self.domain} -H ldaps://#{ldap_server['host']} -r \"#{self.realm}\" -w #{ldap_server['password']} 2>/dev/null"

    puts `echo "#{self.masterpw}\\n#{self.masterpw}\\n" | /usr/sbin/kdb5_ldap_util -D #{ldap_server["bind_dn"]} create -k aes256-cts-hmac-sha1-96 -subtrees "#{self.suffix}" -s -sf /etc/krb5kdc/stash.#{self.domain} -H ldaps://#{ldap_server["host"]} -r "#{self.realm}" -w #{ldap_server["password"]} 2>/dev/null`
  end

  def self.create_kerberos_configuration(ldap_server)
    databases = `ldapsearch -Z -x -D #{ldap_server['bind_dn']} -w #{ldap_server['password']} -H ldap://#{ldap_server['host']} -s base -b "" "(objectClass=*)" namingContexts 2>/dev/null | grep namingContexts:`

    @organisations = []

    databases.split("\n").each do |line|
      if /namingContexts: (.*)/.match(line)
        suffix = $1
        organisation = {}
        
        if not /o=puavo/i.match(suffix) 
          organisation['suffix'] = suffix

          tmp_dbinfo = `ldapsearch -LLL -D #{ldap_server['bind_dn']} -w #{ldap_server['password']} -H ldap://#{ldap_server['host']} -x -s base -b #{suffix} -Z 2> /dev/null`

          if /puavoDomain: (.*)/.match(tmp_dbinfo)
            organisation['domain'] = $1
          end

          if /puavoKerberosRealm: (.*)/.match(tmp_dbinfo)
            organisation['realm'] = $1
          end

          if /puavoKadminPort: (.*)/.match(tmp_dbinfo)
            organisation['kadmin_port'] = $1
          end

          if organisation['domain'] and organisation['realm'] and organisation['kadmin_port']
            @organisations.push organisation
          end
        end
      end
    end

    settings = KerberosSettings.new(@organisations)
  end
end
