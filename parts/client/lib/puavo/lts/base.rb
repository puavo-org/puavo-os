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

      def define_xrandr_disable
        @device.xrandr_disable ?
        { 'XRANDR_DISABLE' => 'True' } : {}
      end

      def define_system_services
        { 'KEEP_SYSTEM_SERVICES' => '"tty1 tty2 tty3 tty4 tty5 tty6"' }
      end

    end
  end
end
