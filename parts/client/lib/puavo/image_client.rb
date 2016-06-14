require 'puavo/gems'
require 'http'
require "httpclient"

class PuavoImageClient

  def self.download(options)

    file = nil
    case options[:output_file].class.to_s
    when "String"
      file = File.open(options[:output_file], "w")
    when "File"
      file = options[:output_file]
    else
      raise OutputFileError, "Invalid --output-file option"
    end

    sha256 = Digest::SHA256.new
    response = HTTP.get(options[:download_url])

    while buffer = response.readpartial(4096)
      sha256.update(buffer) if options.has_key?(:sha256)
      file.write(buffer)
    end

    if options[:output_file].class == String
      file.close
    end

    if options.has_key?(:sha256) && sha256.hexdigest != options[:sha256]
      raise SHA256MismatchError, "Error: SHA256 mismatch, sha256: #{ sha256.hexdigest }"
    end
  end

  class Upload

    attr_accessor :username, :password, :meta_server, :headers

    def initialize(args)
      @client = HTTPClient.new()
      @client.force_basic_auth = true
      @client.send_timeout = 60 * 60 * 2
      @client.receive_timeout = 60 * 60 * 2

      @meta_server = args[:meta_server]
      @headers = { "X-Auth-Host" => args[:domain] }
    end

    def post(*args)
      self.request("post", *args)
    end

    def put(*args)
      self.request("put", *args)
    end

    def request(method, *args)
      counter = 0
      while response = @client.send(method, *args, @headers) do
        if response.status == 401
          puts "Invalid username or password!" if counter > 0
          self.username = ask("Enter your username: ") { |q| q.echo = true } if self.username.nil?
          self.password = ask("Enter your password: ") { |q| q.echo = "*" } if self.password.nil?
          @client.set_auth(self.meta_server, username, password)
          counter += 1
          next
        end

        break
      end

      if response.status =! 200
        puts "Something went wrong! Response status: #{ response.status }, body: #{ response.body }"
        Process.exit(1)
      end

      begin
        response_data = JSON.parse(response.body)
      rescue JSON::ParserError
        puts "Request: #{ method }: #{ args.first }"
        puts "An invalid response data was received: " + response.body
        Process.exit(1)
      end

      return response_data
    end


  end

  class SHA256MismatchError < RuntimeError;  end
  class OutputFileError < RuntimeError;  end
end
