require 'ldap'
require 'socket'

class PuavoLdap
  attr_reader :base, :dn, :password

  Default_ldapserver = '<%= scope.lookupvar('service::ldap::client::serverhosts') %>'
  Puavodomain        = '<%= puavoDomain %>'

  def initialize(ldapserver='localhost')
    @base     = File.read('/etc/puavo/ldap/base'    ).chomp
    @dn       = File.read('/etc/puavo/ldap/dn'      ).chomp
    @password = File.read('/etc/puavo/ldap/password').chomp

    if ldapserver == 'localhost' then
      ldapserver = Default_ldapserver
    end

    if ldapserver
      @conn = LDAP::Conn.new(ldapserver)
      @conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
      @conn.start_tls
      @conn.bind(@dn, @password)

      @my_fqdn = "#{ Socket.gethostname }.#{ Puavodomain }"
    else
      @conn = nil
    end
  end

  def search(filter, &block)
    search_with_base(@base, filter, &block)
  end

  def search_with_base(base, filter, &block)
    return [] unless @conn
    @conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, filter, &block)
  end

  def search_with_baseprefix(baseprefix, filter, &block)
    search_with_base("#{ baseprefix },#{ @base }", filter, &block)
  end

  def lookup_host_by_macaddress(macaddress)
    search("(macAddress=#{ macaddress })") do |entry|
      return entry['puavoHostname']
    end
    return nil
  end

  def autofs_conf(no_mounts_to_this_host=false)
    server_by_path = puavoexports

    if no_mounts_to_this_host
      server_by_path = Hash[
	server_by_path.select { |path, server| server != @my_fqdn }
      ]
    end

    nfsmountopts = '-fstype=nfs4,rw,sec=krb5,nodev,nolock,nosuid,soft'
    autofs_config = []
    server_by_path.map do |path, server|
      if path.match(%r{^/home/([A-Za-z0-9_-]*)$})
	autofs_config << "#{ path } #{ nfsmountopts } #{ server }:#{ path }\n"
      end
    end
    autofs_config.sort.join('')
  end

  def get_all_servers_by_path
    servers = []
    search('(objectClass=puavoServer)') { |entry| servers << entry.to_hash }

    all_servers_by_path = {}
    servers.map do |server|
      Array(server['puavoExport']).each do |path|
        fqdn = "#{ server['puavoHostname'] }.#{ Puavodomain }"
        (all_servers_by_path[path] ||= []).push(fqdn)
      end
    end

    all_servers_by_path
  end

  def puavoexports
    all_servers_by_path = get_all_servers_by_path()

    # handle home directories with duplicates
    server_by_path = Hash[
      all_servers_by_path.map do |path, servers|
        server = servers.count == 1         ? servers.first :
		 servers.include?(@my_fqdn) ? @my_fqdn      :
		 nil
	[ path, server ]
      end
    ]

    # Do not choose a random server in ambiguous situations until we
    # know better what need to do.  The case we should perhaps handle
    # somehow here is an ltsp cluster, where the home directory server is
    # a different one than the boot server and user has a home directory
    # in two different places, where the other is in the cluster and the
    # other is not.
    Hash[ server_by_path.select { |path, server| not server.nil? } ]
  end

  def unbind
    @conn.unbind unless @conn
  end
end
