module Puavo
  module Client
    class Organisation < Model
      model_path :prefix => '/users', :path => "/organisation"
    end
  end
end
