require "fileutils"

# Simple Class for reading and writing data from /etc/puavo
class PuavoEtc

  # Map of puavo attributes and paths on /etc/puavo
  @@attr_paths = {}

  # Create instance getter method for given Puavo attribute.
  #
  # Getters are lazy and memoized. Possible read errors does not occur until
  # user tries to use the given attribute.
  #
  # @param {Symbol} attr Attribute name
  # @param {String} file_path Path to a file under /etc/puavo
  # @param {Hash} options
  #   @param :convert {Symbol} method to call on string
  #   @param :mode {Fixnum} file permissions
  def self.puavo_attr(attr, file_path, options={})
    options[:path] = file_path
    @@attr_paths[attr] = options
    define_method attr do
      return @cache[attr] if @cache[attr]
      value = File.read(File.join(@root, file_path)).chomp
      value = value.send(options[:convert] || :to_s)
      @cache[attr] = value
      return value
    end

  end

  attr_accessor :root

  # Initialize by default with /etc/puavo as the root
  def initialize(root="/etc/puavo")
    @root = root
    @cache = {}
  end

  # Write Puavo attributes to /etc/puavo
  def write(attr, value)
    @cache[attr] = nil
    if not @@attr_paths[attr]
      raise "Unknown Puavo Attribute #{ attr }"
    end
    options = @@attr_paths[attr]

    file_path = File.join(@root, options[:path])
    FileUtils.mkdir_p(File.dirname(file_path))

    if value.to_s.empty?
      value = ""
    else
      value = "#{ value }\n"
    end

    File.open(file_path, "w", (options[:mode] || 0644)) do |f|
      f.print(value)
    end

    if options[:group]
      FileUtils.chown("root", options[:group], file_path)
    end
  end

  # Get puavo attribute or nil if the file is missing
  def get(attr)
    begin
      send(attr)
    rescue Errno::ENOENT
      nil
    end
  end

  def resolve_puavo_url
    begin
      return puavo_development_url
    rescue Errno::ENOENT
      return "https://#{ domain }"
    end
  end

  # Puavo Attribute definitions
  puavo_attr :id, "id", :convert => :to_i
  puavo_attr :domain, "domain"
  puavo_attr :topdomain, "topdomain"
  puavo_attr :hostname, "hostname"
  puavo_attr :hosttype, "hosttype"
  puavo_attr :puavo_development_url, "puavo_development_url"

  puavo_attr :ldap_dn, "ldap/dn"
  puavo_attr :ldap_base, "ldap/base"
  puavo_attr :ldap_master, "ldap/master"
  puavo_attr :ldap_slave, "ldap/slave"
  puavo_attr :ldap_password, "ldap/password", {
    :mode => 0640,
    :group => "puavo"
  }
  puavo_attr :krb_master, "kerberos/master"
  puavo_attr :krb_realm, "kerberos/realm"
  puavo_attr :krb_toprealm, "kerberos/toprealm"

  puavo_attr :root_ca, "certs/rootca.pem"
  puavo_attr :host_crt, "certs/host.crt"
  puavo_attr :host_key, "certs/host.key"
  puavo_attr :org_ca_bundle, "certs/orgcabundle.pem"

  puavo_attr :kernel_version, "kernel/version"
  puavo_attr :kernel_arguments, "kernel/arguments"

  puavo_attr :primary_ltsp_server, "primary_ltsp_server"

  puavo_attr :ds_puavo_dn, "ds/puavo/dn"
  puavo_attr :ds_puavo_password, "ds/puavo/password"
  puavo_attr :ds_puavo_ticket_dn, "ds/puavo-ticket/dn"
  puavo_attr :ds_puavo_ticket_password, "ds/puavo-ticket/password"
  puavo_attr :ds_pw_mgmt_dn, "ds/pw-mgmt/dn"
  puavo_attr :ds_pw_mgmt_password, "ds/pw-mgmt/password"
  puavo_attr :ds_puppet_dn, "ds/puppet/dn"
  puavo_attr :ds_puppet_password, "ds/puppet/password", :mode => 0640
  puavo_attr :ds_kdc_dn, "ds/kdc/dn"
  puavo_attr :ds_kdc_password, "ds/kdc/password", :mode => 0640
  puavo_attr :ds_kadmin_dn, "ds/kadmin/dn"
  puavo_attr :ds_kadmin_password, "ds/kadmin/password", :mode => 0640
  puavo_attr :ds_monitor_dn, "ds/monitor/dn"
  puavo_attr :ds_monitor_password, "ds/monitor/password", :mode => 0640
  puavo_attr :ds_slave_dn, "ds/slave/dn"
  puavo_attr :ds_slave_password, "ds/slave/password", :mode => 0640
end


# Always instantiate PuavoEtc with the default /etc/puavo for easy access.
# This should not break anything unless it is actually used since it's lazy.
PUAVO_ETC = PuavoEtc.new
# XXX: Detect laptop and use /state whatever for it?
