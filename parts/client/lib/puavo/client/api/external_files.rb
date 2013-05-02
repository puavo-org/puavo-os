module Puavo
  module Client
    module API
      class ExternalFiles < Base
        model_name "ExternalFile"

        def file_data(name)
          file_path = "#{ url_prefix }/#{ self.model_name.model_path }/#{ name }"
          rest file_path
        end

      end
    end
  end
end
