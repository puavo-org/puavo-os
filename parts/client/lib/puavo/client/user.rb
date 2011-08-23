module Puavo
  module Client
    class User < Model
      model_path :prefix => '/users', :path => "/users"
    end
  end
end
