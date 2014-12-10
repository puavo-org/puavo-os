require 'puavo-ds/templates'

class KerberosSettings

  TMP = "/tmp/puavo-ds-kerberos-tmp"

  def self.find_all_organisations(host, dn, password)
    databases = `ldapsearch -Z -x -D #{dn} -w #{password} -H ldap://#{host} -s base -b "" "(objectClass=*)" namingContexts 2>/dev/null | grep namingContexts:`

    kerberos_organisations = []

    databases.split("\n").each do |line|
      if /namingContexts: (.*)/.match(line)
        suffix = $1
        organisation = {}
        
        if not /o=puavo/i.match(suffix) 
          organisation['suffix'] = suffix

          tmp_dbinfo = `ldapsearch -LLL -D #{dn} -w #{password} -H ldap://#{host} -x -s base -b #{suffix} -Z 2> /dev/null`

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
            kerberos_organisations.push organisation
          end
        end
      end
    end

    return kerberos_organisations

  end

  def self.generate_new_password( length )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(length) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def initialize(args)
    @ldap_host = args[:ldap_host]
    @ldap_dn = args[:ldap_dn]
    @ldap_password = args[:ldap_password]
    
    @organisations = self.class.find_all_organisations(@ldap_host, @ldap_dn, @ldap_password)
  end

  def kdc_conf
    if @kdc_conf
      return @kdc_conf
    else
      kdc_conf_erb = File.read("#{ TEMPLATES_PATH }/kdc.conf.erb")
      kdc_conf = ERB.new(kdc_conf_erb, 0, "%<>")

      @kdc_conf = kdc_conf.result(getBinding)

      return @kdc_conf
    end
  end

  def krb5_conf
    if @krb5_conf
      return @krb5_conf
    else
      krb5_conf_erb = File.read("#{ TEMPLATES_PATH }/krb5.conf.erb")
      krb5_conf = ERB.new(krb5_conf_erb, 0, "%<>")

      @krb5_conf = krb5_conf.result(getBinding)

      return @krb5_conf
    end
  end

  def kadm5_acl
    if @kadm5_acl
      return @kadm5_acl
    else
      kadm5_acl_erb = File.read("#{ TEMPLATES_PATH }/kadm5.acl.erb")
      kadm5_acl = ERB.new(kadm5_acl_erb, 0, "%<>")

      @kadm5_acl = kadm5_acl.result(getBinding)

      return @kadm5_acl
    end
  end

  def daemon_args
    organisation_args = @organisations.collect do |org|
      "-r " + org['realm']
    end.join(" ")
    return "KRB5_KDC_START=1\nDAEMON_ARGS=\"#{ organisation_args }\""
  end

  def getBinding
    return binding()
  end

  def write_configurations_to_file
    # Generate configuration by ldap data
    begin
      File.new(TMP)
    rescue Errno::ENOENT
      Dir.mkdir(TMP)
    end

    # Create new konfiguration files to tmp directory
    File.open("#{TMP}/kdc.conf", "w") do |file|
      file.write(self.kdc_conf)
    end

    File.open("#{TMP}/krb5.conf", "w") do |file|
      file.write(self.krb5_conf)
    end

    File.open("#{TMP}/kadm5.acl", "w") do |file|
      file.write(self.kadm5_acl)
    end

    File.open("#{TMP}/krb5-kdc", "w") do |file|
      file.write(self.daemon_args)
    end
  end

  def diff
    puts "Show differences: #{TMP}/kdc.conf /etc/krb5kdc/kdc.conf"
    print `diff #{TMP}/kdc.conf /etc/krb5kdc/kdc.conf`
    puts

    puts "Show differences: #{TMP}/krb5.conf /etc/krb5.conf"
    print `diff #{TMP}/krb5.conf /etc/krb5.conf`
    puts

    puts "Show differences: #{TMP}/kadm5.acl /etc/krb5kdc/kadm5.acl"
    print `diff #{TMP}/kadm5.acl /etc/krb5kdc/kadm5.acl`
    puts

    puts "Show differences: #{TMP}/krb5-kdc /etc/default/krb5-kdc"
    print `diff #{TMP}/krb5-kdc /etc/default/krb5-kdc`
    puts
  end

  def replace_server_configurations
    `mv #{TMP}/kdc.conf /etc/krb5kdc/kdc.conf`
    `mv #{TMP}/krb5.conf /etc/krb5.conf`
    `mv #{TMP}/kadm5.acl /etc/krb5kdc/kadm5.acl`
    `mv #{TMP}/krb5-kdc /etc/default/krb5-kdc`
    fix_file_permissions
  end

  def fix_file_permissions
    `chown -R root:openldap /etc/krb5kdc`
    `chmod 0750 /etc/krb5kdc`
    `chmod 0640 /etc/krb5kdc/*`
    `chown root:openldap /etc/krb5.secrets`
    `chmod 0640 /etc/krb5.secrets`
  end
end
  
class KerberosRealm

  def initialize(args)
    @ldap_host = args[:ldap_host]
    @ldap_dn = args[:ldap_dn]
    @ldap_password = args[:ldap_password]
    @realm = args[:realm]
    @masterpw = args[:masterpw]
    @suffix = args[:suffix]
    @domain = args[:domain]
  end

  # Create kerberos ldap tree and stash file
  def save
    puts `echo "#{@masterpw}\\n#{@masterpw}\\n" | /usr/sbin/kdb5_ldap_util -D #{@ldap_dn} create -k aes256-cts-hmac-sha1-96 -subtrees "#{@suffix}" -s -sf /etc/krb5kdc/stash.#{@domain} -H ldaps://#{@ldap_host} -r "#{@realm}" -w #{@ldap_password} 2>/dev/null`
    `chown root:openldap /etc/krb5kdc/stash.#{@domain}`
    `chmod 0640 /etc/krb5kdc/stash.#{@domain}`
  end
end
