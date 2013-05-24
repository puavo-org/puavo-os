module Puavo
  module Client
    class ExternalFile < Model
      include Puavo::Client::HashMixin::ExternalFile
      model_path :prefix => '/api/v2', :path => "/external_files"

      def get_data
        file_path = "#{ @api.url_prefix }/#{ @api.model_name.model_path }/#{ name }"
        @api.rest(file_path)
      end

    end
  end
end
