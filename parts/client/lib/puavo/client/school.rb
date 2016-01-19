module Puavo
  module Client
    class School < Model
      include Puavo::Client::HashMixin::School

      model_path :prefix => '/users', :path => "/schools"
    end
  end
end
