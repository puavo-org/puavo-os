module PuavoSetup

  @@configuration = {}

  def self.configuration
    if @@configuration.empty?
      load_configuration_from_file
    end
    return @@configuration
  end

  def self.load_configuration_from_file
    configuration_file = File.join('config', 'puavo.yml')
    if File.exist?(configuration_file)
      # Set default configuration values
      default_configuration = {}
      default_configuration['server'] = {}
      default_configuration['server']['schemas'] = ["cosine", "nis", "inetorgperson", "misc", "ppolicy", "samba",
                                              "autofs", "kerberos", "eduorg", "eduperson", "edumember",
                                              "puppet", "dnsdomain2", "printer", "puavo"]
      default_configuration['server']['server_uri'] = 'ldapi:///'
      default_configuration['server']['server_port'] = 389
      default_configuration['server']['cert_serial'] = 1
      @@configuration = @@configuration.merge( YAML.load( File.open(configuration_file) ) )
      # Set default configuration. File's values overwrite default values.
      default_configuration.each do |key,value|
        @@configuration[key] = value.merge(@@configuration[key])
      end
    end
  end

  class ServerSettings
    attr_accessor :server_uri, :schemas, :schema_dir, :server_fqdn, :ca_fqdn, :server_port, :connect_dn, :connect_password, :cert_organisation, :cert_unit, :cert_locality, :cert_state, :cert_country, :cert_serial, :cert_expiration_days, :id_pool

    def initialize(params)
      @server_uri = params[:server_uri]
      @schemas = params[:schemas]
      @server_fqdn = params[:server_fqdn]
      @server_port = params[:server_port]
      @ca_fqdn = params[:ca_fqdn]
      @connect_dn = params[:connect_dn]
      @connect_password = params[:connect_password]
      @cert_organisation = params[:cert_organisation]
      @cert_unit = params[:cert_unit]
      @cert_locality = params[:cert_locality]
      @cert_state = params[:cert_state]
      @cert_country = params[:cert_country]
      @cert_serial = params[:cert_serial]
      @cert_expiration_days = params[:cert_expiration_days]
      @id_pool = params[:id_pool]
    end
  end

  class DatabaseSettings
    attr_accessor :server, :suffix, :rootdn, :rootpw, :domain, :kerberos_realm, :kdc_ldapdn, :kdc_ldappw, :kadmin_ldapdn, :kadmin_ldappw, :kerberos_masterpw, :samba_domain, :samba_rootpw, :samba_sid, :org_name, :puavo_user_password

    def initialize(params)
      sid1 = rand(100000000)
      sid2 = rand(100000000)
      sid3 = rand(100000000)
      
      @samba_sid = "S-1-5-21-#{sid1}-#{sid2}-#{sid3}"

      @server = params[:server]
      @suffix = params[:suffix]
      @domain = params[:domain]
      @rootdn = params[:rootdn]
      @rootpw = params[:rootpw]
      @kerberos_realm = params[:kerberos_realm]
      @kdc_ldapdn = params[:kdc_ldapdn]
      @kdc_ldappw = params[:kdc_ldappw]
      @kadmin_ldapdn = params[:kadmin_ldapdn]
      @kadmin_ldappw = params[:kadmin_ldappw]
      @kerberos_masterpw = params[:kerberos_masterpw]
      @samba_domain = params[:samba_domain]
      @samba_rootpw = params[:samba_rootpw]
      @org_name = params[:org_name]
      @puavo_user_password = params[:puavo_user_password]

      if params[:samba_sid]
        @samba_sid = params[:samba_sid]
      end
    end
  end
end
