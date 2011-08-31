module Puavo
  module Client
    class Group < Model
      model_path :prefix => '/users', :path => "/groups"

      def members
        User.parse( api,
                    api.rest( api.url_prefix + 
                              Group.model_path(:school_id => self.school_id) +
                              "/#{self.puavo_id}/members" ).parsed_response )
      end
    end
  end
end
