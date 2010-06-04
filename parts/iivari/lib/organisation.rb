class Organisation

  cattr_accessor :configurations, :configurations_by_host
  attr_accessor :organisation_key

  def schools
    School.all
  end

  def name
    value_by_key("name")
  end

  def host
    value_by_key("host")
  end

  def ldap_host
    value_by_key("ldap_host")
  end

  def ldap_base
    value_by_key("ldap_base")
  end

  def value_by_key(key)
    if organisation_key
      return self.class.configurations[@organisation_key][key]
    else
      logger.info "Organisation key is not set!"
      nil
    end
  end

  def logger
    self.class.logger
  end

  class << self
    def find(key)
      if self.configurations.has_key?(key)
        organisation = Organisation.new
        organisation.organisation_key = key
        return organisation
      else
        false
      end
    end

    def find_by_host(host)
      if configurations_by_host.has_key?(host)
        organisation = Organisation.new
        organisation.organisation_key = self.configurations_by_host[host]
        return organisation
      else
        logger.info "Can not find organisation by host: #{host}"
        false
      end
    end

    def configurations
      self.load_configurations if @@configurations.nil?
      return @@configurations
    end
    def configurations_by_host
      self.load_configurations if @@configurations_by_host.nil?
      return @@configurations_by_host
    end

    def load_configurations
      logger.debug "Load ldap configurations from file"
      configuration_file = File.join(RAILS_ROOT, 'config', 'organisations.yml')
      if File.exist?(configuration_file)
        self.configurations = YAML.load(ERB.new(IO.read(configuration_file)).result)
        self.configurations_by_host = {}
        self.configurations.each do |key, value|
          self.configurations_by_host[ value["host"] ] = key
        end
      end
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
end
