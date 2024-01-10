require 'net/ldap'

class PuavoLdap
  attr_reader :base, :dn, :password

  Puavodomain   = File.read('/etc/puavo/domain').chomp
  Puavohostname = File.read('/etc/puavo/hostname').chomp
  My_FQDN       = "#{ Puavohostname }.#{ Puavodomain }"

  def initialize
    @base = File.read('/etc/puavo/ldap/base'    ).chomp

    dn       = File.read('/etc/puavo/ldap/dn'      ).chomp
    password = File.read('/etc/puavo/ldap/password').chomp

    connection_args = {
      :auth => {
        :method   => :simple,
        :username => dn,
        :password => password,
      },
      :host => My_FQDN,
      :port => 389,
      :encryption => {
        :method => :start_tls,
        :tls_options => {
          :ca_file     => '/etc/puavo-conf/rootca.pem',
          :verify_mode => OpenSSL::SSL::VERIFY_PEER,
        },
      }
    }

    @ldap = Net::LDAP.new(connection_args)
  end

  def search(filter, &block)
    search_with_base(@base, filter, &block)
  end

  def search_with_base(base, filter, &block)
    @ldap.search(:base => base, :filter => filter, &block)
  end

  def search_with_baseprefix(baseprefix, filter, &block)
    search_with_base("#{ baseprefix },#{ @base }", filter, &block)
  end
end
