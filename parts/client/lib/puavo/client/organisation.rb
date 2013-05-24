module Puavo
  module Client
    class Organisation < Model
      include Puavo::Client::HashMixin::Organisation

      model_path :prefix => '/users', :path => "/organisation"
    end
  end
end
