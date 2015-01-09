require 'ipaddress'

ENV['LANG'] = 'C'

class Interface
  def initialize(name)
    @name = name
    @ifconfig = `ifconfig #{name}`
  end

  def ip
    if /inet addr:(\d+)\.(\d+)\.(\d+)\.(\d+)/.match(@ifconfig)
      ip = "#{$1}.#{$2}.#{$3}.#{$4}"

      if /Mask:(\d+)\.(\d+)\.(\d+)\.(\d+)/.match(@ifconfig)
        mask = "#{$1}.#{$2}.#{$3}.#{$4}"

        return IPAddress "#{ip}/#{mask}"
      end
    end

    return nil
  end

  def ranges(mask)
    subnets = self.ip.subnet(mask)
    ranges = Array.new
    iface_ip = self.ip

    subnets.each do |subnet|
      if !subnet.include?(iface_ip)
        ranges << [subnet.first.to_s, subnet.last.to_s]
      end
    end

    ranges
  end
end

Facter.add('ltsp_iface_ip') do
  setcode do
    Interface.new('ltsp0').ip.to_s
  end
end
