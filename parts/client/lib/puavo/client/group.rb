module Puavo
  module Client
    class Group < Model
      model_path :prefix => '/users', :path => "/groups"
    end
  end
end
