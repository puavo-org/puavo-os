module Puavo
  class LtsConfig
    
    def initialize(organisation, school, device)
      @organisation = organisation
      @school = school
      @device = device

      @lts_data = {}

      unless ['thinclient', 'fatclient', 'ltspserver', 'laptop'].include?(@device.device_type)
        raise "Invalid device type: #{@device.device_type}"
      end

      send @device.device_type + "_lts_config"
    end

    def output
      "[#{ @device.mac_address }]\n" +
        @lts_data.map { |key, value| "\t#{ key } = #{ value }\n" }.sort.join
    end

    private

    def laptop_lts_config
      @lts_data = {
        'LOCAL_APPS'           => 'False',
        'LOCALDEV'             => 'False',
        'LTSP_FATCLIENT'       => 'True',
        'NBD_SWAP'             => 'False',
        'SCREEN_07'            => 'lightdm',
        'SYSLOG'               => 'False',
        'XKBLAYOUT'            => 'fi',
      }

      @lts_data.merge!( define_tags )
      @lts_data.merge!( define_default_printer )
      # FIXME
      # @lts_data.merge( define_xserver )
      @lts_data.merge!( define_xrandr_disable )
      @lts_data.merge!( define_system_services )
    end

    def thinclient_lts_config
    end

    def fatclient_lts_config
    end

    def ltspserver_lts_config
    end

    def define_tags
      @device.tags ? { 'PUAVO_TAGS' => Array(@device.tags).join(" ") } : {}
    end

    def define_default_printer
      @device.default_printer ? { 'LDM_PRINTER_DEFAULT' => @device.default_printer } : {}
    end
    
    def define_xserver
      @device.xserver ? { 'XSERVER' => @device.xserver } : {}
    end

    def define_xrandr_disable
      @device.xrandr_disable ?
      { 'XRANDR_DISABLE' => 'True' } : {}
    end

    def define_system_services
      { 'KEEP_SYSTEM_SERVICES' => '"tty1 tty2 tty3 tty4 tty5 tty6"' }
    end

  end
end
