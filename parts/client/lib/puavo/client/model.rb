module Puavo
  module Client
    class Model
      def initialize(api, data)
        @data = data
        @api = api
      end

      def api
        @api
      end

      def method_missing(method, *args, &block)
        if @data.has_key?(method.to_s)
          @data[method.to_s]
        else
          super
        end
      end

      def keys
        @data.keys
      end

      def self.parse(api, data)
        data.map do |d|
          new(api, d)
        end
      end

      def self.model_path(args = {})
        @path = args[:path] if args.has_key?(:path)
        @prefix = args[:prefix] if args.has_key?(:prefix)
        if args.has_key?(:school_id)
          return "#{@prefix}/#{args[:school_id]}#{@path}"
        end
        return "#{@prefix}#{@path}"
      end
    end
  end
end
