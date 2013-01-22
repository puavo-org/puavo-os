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

  def organisation
    filter = '(objectClass=puavoEduOrg)'
    find_with_filter(filter)
  end

  def find_with_filter(filter, type = :first)

    if type == :first
      # Find first entry from ldap

      result = {}

      @conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, filter) do |entry|
        result = ldap_entry_to_hash(entry)
        break
      end
    else
      # Find all entries from ldap

      result = []

      @conn.search(base, LDAP::LDAP_SCOPE_SUBTREE, filter) do |entry|
        result.push ldap_entry_to_hash(entry)
      end
   
    end

    result
  end

  def ldap_entry_to_hash(entry)
    hash_entry = {}
    entry.to_hash.each do |key,value|
      # Use first value if Array length is 1
      if value.class == Array && value.count <= 1
        hash_entry[key] = value.first
      else
        hash_entry[key] = value
      end
    end
    hash_entry
  end
  
  def self.escape(filter)
    filter.gsub(ESCAPES_RE) { |char| "\\" + ESCAPES[char] }
  end

end
