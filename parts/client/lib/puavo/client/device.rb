module Puavo
  module Client
    class Device < Model
      model_path :prefix => '/devices/api/v2', :path => "/devices"
    end
  end
end
