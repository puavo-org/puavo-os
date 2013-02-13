module Puavo
  module Client
    class Server < Model
      model_path :prefix => '/devices/api/v2', :path => "/servers"
    end
  end
end
