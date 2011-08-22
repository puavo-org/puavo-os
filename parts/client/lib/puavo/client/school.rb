module Puavo
  module Client
    class School < Model
      model_path :prefix => '/users', :path => "/schools"
    end
  end
end
