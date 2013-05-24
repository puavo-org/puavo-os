module Puavo
  module Client
    class Model
      def initialize(api, data)
        @data = data
        @api = api
      end
      
      def self.new_by_ldap_entry(entry)
        new_object = self.new( nil, entry )
        new_object.data = new_object.ldap_prettify
        new_object
      end


      def api
        @api
      end

      def method_missing(method, *args, &block)
        if @data.has_key?(method.to_s)
          @data[method.to_s]
        elsif method.to_s == "classes" && @data.has_key?("objectClass")
          @data["objectClass"]
        else
          super
        end
      end

      def keys
        @data.keys
      end

      def data
        @data
      end

      def data=(new_data)
        @data = new_data
      end

      def self.parse(api, data)
        data.map do |d|
          new(api, d)
        end
      end


      def self.model_path(args = {})
        @path = args[:path] if args.has_key?(:path)
        @prefix = args[:prefix] if args.has_key?(:prefix)

        url = @prefix.to_s

        if args.has_key?(:school_id)
          url += "/#{args[:school_id]}"
        end

        url += @path.to_s

        if args.has_key?(:id)
          url += "/#{args[:id]}"
        end

        return url
      end
    end
  end
end
