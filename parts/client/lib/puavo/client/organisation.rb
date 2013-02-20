module Puavo
  module Client
    class Organisation < Model
      extend Puavo::Client::HashMixin::Organisation

      model_path :prefix => '/users', :path => "/organisation"
    end
  end
end
