module Puavo
  module Client
    class Server < Model
      include Puavo::Client::HashMixin::Server

      model_path :prefix => '/devices/api/v2', :path => "/servers"
    end
  end
end
