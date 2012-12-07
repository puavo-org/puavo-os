require 'ldap'

class PuavoLdap
  attr_reader :base, :dn, :password

  ESCAPES = {
    "\0" => '00',
    '*'  => '2A',
    '('  => '28',
    ')'  => '29',
    '\\' => '5C' }

  ESCAPES_RE = Regexp.new("[#{ ESCAPES.keys.map { |e| Regexp.escape(e) }.join }]")

  def initialize(ldapserver='localhost')
    @base       = File.read('/etc/puavo/ldap/base'    ).chomp
    @dn         = File.read('/etc/puavo/ldap/dn'      ).chomp
    @password   = File.read('/etc/puavo/ldap/password').chomp
    #ldapserver  = File.read('/etc/puavo/ldap/master'  ).chomp

    if ldapserver
      @conn = LDAP::Conn.new(ldapserver)
      @conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
      @conn.start_tls
      @conn.bind(@dn, @password)

    else
      @conn = nil
    end
  end

  def netboot_device_by_mac(mac)
    mac = self.class.escape(mac)
    filter = "(&(objectClass=puavoNetbootDevice)(macAddress=#{ mac }))"
    find_with_filter(filter)
  end

  def device_by_mac(mac)
    mac = self.class.escape(mac)
    filter = "(macAddress=#{ mac })"
    find_with_filter(filter)
  end

  def find_with_filter(filter, type = :first)
    result = nil

    if type == :first
      @conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, filter) do |entry|
        result = entry.to_hash
        break
      end
   
      result.each do |key,value|
        if value.class == Array && value.count <= 1
          result[key] = value.first
        end
      end
    end

    result
  end

  def self.escape(filter)
    filter.gsub(ESCAPES_RE) { |char| "\\" + ESCAPES[char] }
  end

end
