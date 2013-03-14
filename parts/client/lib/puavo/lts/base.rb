require 'shellwords'

module Puavo
  module Lts

    def self.new(organisation, school, device)
      unless ['thinclient', 'fatclient', 'ltspserver', 'laptop'].include?(device.device_type)
        raise "Invalid device type: #{device.device_type}"
      end

      case device.device_type
      when "thinclient"
        Puavo::Lts::Thinclient.new(organisation, school, device)
      when "fatclient"
        Puavo::Lts::Fatclient.new(organisation, school, device)
      when "ltspserver"
        Puavo::Lts::LtspServer.new(organisation, school, device)
      when "laptop"
        Puavo::Lts::Laptop.new(organisation, school, device)
      end
    end

    class Base

      def output
        "[#{ @device.mac_address }]\n" +
          @lts_data.map { |key, value| "\t#{ key } = #{ value }\n" }.sort.join
      end

      def define_tags
        @device.tags ? { 'PUAVO_TAGS' => Array(@device.tags).join(" ") } : {}
      end

      def define_default_printer
        @device.default_printer ? { 'LDM_PRINTER_DEFAULT' => @device.default_printer } : {}
      end
      
      def define_xserver_driver
        @device.xserver_driver ? { 'XSERVER' => @device.xserver_driver } : {}
      end

      def define_xrandrs
        xrandr_definition = {}
        xrandr_definition.merge!( @device.xrandr_disable ?
                                  { 'XRANDR_DISABLE' => 'True' } : {} )

        if @device.xrandrs
           @device.xrandrs.each_index do |i|
            xrandrsetting = xrandrline( @device.xrandrs[i] )
            xrandrsetting.each do |key, value|
              varname = "XRANDR_#{ key.upcase }_#{ i }"
              xrandr_definition.merge!( { "#{varname}" => value } )
            end
          end
        end

        xrandr_definition
      end

      def xrandrline(line)
        Hash[ * Shellwords.shellwords(line).map { |s| s.split('=',2) }.flatten ]
      end

      def define_resolution
        definition = {}
        definition.merge!( @device.resolution ? { 'X_MODE_0' => @device.resolution } : {} )
        definition.merge!( @device.horizontal_sync ? { 'X_HORZSYNC' => @device.horizontal_sync } : {} )
        definition.merge!( @device.vertical_refresh ? { 'X_VERTREFRESH' => @device.vertical_refresh } : {} )
      end

      def define_auto_power_off
        definition = {
          'AUTOPOWEROFF' => 'Y',
          'AUTOPOWEROFF_START' => 7,
          'AUTOPOWEROFF_END' => 16,
          'AUTOPOWEROFF_STARTUP_DELAY' => 30,
          'AUTOPOWEROFF_IDLE_TIME' => 30
        }

        # Defaults by organisation
        settings_by_organisation = {}
        if @organisation.auto_power_off_mode == 'off'
          settings_by_@organisation['AUTOPOWEROFF'] = 'N'
        elsif @organisation.auto_power_off_mode == 'custom'
          settings_by_@organisation['AUTOPOWEROFF'] = 'Y'
          settings_by_@organisation['AUTOPOWEROFF_START'] =
            @organisation.auto_power_on_hour if @organisation.auto_power_on_hour
          settings_by_@organisation['AUTOPOWEROFF_END'] =
            @organisation.auto_power_off_hour if @organisation.auto_power_off_hour
        end
        
        definition.merge!(settings_by_organisation)

        # Settings by device
        settings_by_device = {}
        if @device.auto_power_off_mode == 'off'
          settings_by_device['AUTOPOWEROFF'] = 'N'
        elsif @device.auto_power_off_mode == 'custom'
          settings_by_device['AUTOPOWEROFF'] = 'Y'
          settings_by_device['AUTOPOWEROFF_START'] = @device.auto_power_on_hour if @device.auto_power_on_hour
          settings_by_device['AUTOPOWEROFF_END'] = @device.auto_power_off_hour if @device.auto_power_off_hour
        end
        
        definition.merge!(settings_by_device)
      end

      def define_wlan
        definition = {}
        if @school.class == Puavo::Client::School
          index = 1
          @school.wlan_ssids.each do |ssid|
            lts_key = "WLAN_SSID_%02d" % index
            definition[lts_key] = '"' + ssid + '"'
            index += 1
          end
        end
        definition
      end

      def boot_server_fqdn
        "#{PUAVO_ETC.hostname}.#{PUAVO_ETC.domain}"
      end
    end
  end
end
