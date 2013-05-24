module Puavo
  module Client
    class Device < Model
      include Puavo::Client::HashMixin::Device

      model_path :prefix => '/devices/api/v2', :path => "/devices"
    end
  end
end
