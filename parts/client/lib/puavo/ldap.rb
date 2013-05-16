require 'resolv'
require 'ldap'
require 'puavo/etc'

module Puavo

  # raises Resolv::ResolvError if not found
  def self.resolve_ldap(puavo_domain)
    name = "_ldap._tcp.#{ puavo_domain }"
    resolver = Resolv::DNS.new
    res = resolver.getresource(name, Resolv::DNS::Resource::IN::SRV)
    return res.target.to_s
  end

  class Ldap
    attr_reader :base, :dn, :password

    ESCAPES = {
      "\0" => '00',
      '*'  => '2A',
      '('  => '28',
      ')'  => '29',
      '\\' => '5C' }

    ESCAPES_RE = Regexp.new("[#{ ESCAPES.keys.map { |e| Regexp.escape(e) }.join }]")

    # Initialize ldap connection with Puavo style. If no arguments are supplied
    # Puavo::Ldap will try get dn&password from /etc/puavo. If they are not
    # found (fat clients) it will try to make a sasl bind with GSSAPI.
    #
    # Login data can be overridden with an options Hash:
    #  dn: force dn
    #  password: force password
    #  base: force base
    #  server: force server
    #  sasl: set to true to force sasl bind
    def initialize(*args)
      options = args[0] || {}

      if not options[:sasl]
        begin
          @dn = options[:dn] || PUAVO_ETC.ldap_dn
          # Let PUAVO_ETC.ldap_password to throw permision denied if run as non
          # root
          @password = options[:password] || PUAVO_ETC.ldap_password
        rescue Errno::ENOENT
          # If no dn was given and one was not found from /etc/puavo fallback to
          # sasl.
          options[:sasl] = true
        end
      end

      @base = options[:base] || PUAVO_ETC.ldap_base

      @server = options[:server] || begin
        Puavo.resolve_ldap(PUAVO_ETC.domain)
      rescue Resolv::ResolvError
        nil
      end || PUAVO_ETC.get(:ldap_slave) || PUAVO_ETC.ldap_master

      @conn = LDAP::Conn.new(@server)
      @conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
      @conn.start_tls

      if options[:sasl]
        @conn.sasl_bind("", "GSSAPI")
      else
        @conn.bind(@dn, @password)
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

    def school_by_dn(dn)
      unless puavo_id_match = dn.to_s.match(/puavoId=([0-9]+)/)
        return nil
      end
      school_puavo_id = puavo_id_match[1]
      filter = "(&(objectClass=puavoSchool)(puavoId=#{school_puavo_id}))"
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

      return nil if result.empty?

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

    def all_bases
      @conn.search("", LDAP::LDAP_SCOPE_BASE, "(objectClass=*)", ["namingContexts"]) do |e|
        return e.get_values("namingContexts")
      end
    end

    def unbind
      @conn.unbind
    end
  end
end
