module Puavo
  module Client
    class Device < Model
      model_path :prefix => '/devices', :path => "/devices"
    end
  end
end
