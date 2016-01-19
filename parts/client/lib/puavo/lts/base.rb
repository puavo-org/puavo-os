require 'shellwords'

module Puavo
  module Lts

    def self.new(organisation, school, device)
      class_by_device_type = {
        'fatclient'           => Puavo::Lts::Fatclient,
        'laptop'              => Puavo::Lts::Laptop,
        'ltspserver'          => Puavo::Lts::LtspServer,
        'thinclient'          => Puavo::Lts::Thinclient,
        'unregistered'        => Puavo::Lts::Unregistered,
        'wirelessaccesspoint' => Puavo::Lts::Wirelessaccesspoint,
      }

      device_class = class_by_device_type[device.device_type]
      if device_class then
        device_class.new(organisation, school, device)
      else
        raise "Invalid device type: #{ device.device_type }"
      end
    end

    class Base

      def output
        "[default]\n" +
          @lts_data.map { |key, value| "\t#{ key } = #{ value }\n" }.sort.join
      end

      def define_tags
        @device.tags.empty? ? {} : { 'PUAVO_TAGS' => Array(@device.tags).join(" ") }
      end

      def define_default_locale
        lang = (
          # Language priorities
          @device.preferred_language ||
          @school.preferred_language ||
          @organisation.preferred_language
        )

        locales_by_lang = {
          'de' => 'de_DE.UTF-8',
          'en' => 'en_GB.UTF-8',
          'fi' => 'fi_FI.UTF-8',
          'ru' => 'ru_RU.UTF-8',
          'sv' => 'sv_FI.UTF-8',
        }

        locale = locales_by_lang[lang]
        locale ? { 'DEFAULT_LOCALE' => locale } : {}
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
            begin
              wlan_settings = JSON.parse(ssid)
              definition[lts_key] =
                '"' +
                "#{ wlan_settings['type'] }:#{ wlan_settings['ssid'] }:#{ wlan_settings['password'] }" +
                '"'
            rescue JSON::ParserError
              definition[lts_key] = '"' + ssid + '"'
            end
            index += 1
          end
          definition["WLAN_CHANNEL"] = @school.wlan_channel if @school.wlan_channel
        end
        definition
      end

      def boot_server_fqdn
        "#{PUAVO_ETC.hostname}.#{PUAVO_ETC.domain}"
      end
    end
  end
end
