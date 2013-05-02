module Puavo
  module Client
    class ExternalFile < Model
      extend Puavo::Client::HashMixin::ExternalFile

      model_path :prefix => '/api/v2', :path => "/external_files"
    end
  end
end
