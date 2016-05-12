
require "puavo/gems"
require "gssapi"
require "http"
require "optparse"
require "resolv"
require "addressable/uri"


if ENV["PUAVO_REST_CLIENT_VERBOSE"]
    $puavo_rest_client_verbose = true
end

class PuavoRestClient

  class Error < StandardError; end
  class ResolvFail < Error; end
  class BadStatusCode < Error
    attr_accessor :response
    def initialize(response)
      @response = response
    end
  end

  SUCCESS_STATUS_CODES = [200]

  RETRY_FALLBACK_EXCEPTIONS = [
    BadStatusCode,
    Errno::ENETUNREACH
  ]

  def self.verbose(*msg)
    text, *args = msg
    if $puavo_rest_client_verbose
      STDERR.puts("puavo-rest-client: #{ text }", *args)
    end
  end

  def warn(*msg)
    return if @options[:silent]
    text, *args = msg
    STDERR.puts("WARN #{ text }", *args)
  end

  def verbose(*msg)
    self.class.verbose(*msg)
  end

  def verbose_log_headers(headers)
    headers.each do |k, v|
      verbose("    #{k}: #{v}")
    end
  end


  def self.public_ssl
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
    ctx.ca_path = "/etc/ssl/certs"
    return ctx
  end

  def self.custom_ssl(ca_file="/etc/puavo/certs/rootca.pem")
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
    ctx.ca_file = ca_file
    return ctx
  end


  def self.resolve_apiserver_dns(puavo_domain)

      res = Resolv::DNS.open do |dns|
        dns.getresources(
          "_puavo-api._tcp.#{ puavo_domain }",
          Resolv::DNS::Resource::IN::SRV
        )
      end

      if res.nil? || res.empty?
        raise ResolvFail, "Empty DNS response"
      end

      server_host = res.first.target.to_s
      if !server_host.end_with?(puavo_domain)
        raise ResolvFail, "Invalid value. #{ server_host } does not match with requested puavo domain #{ puavo_domain }. Using master puavo-rest as fallback"
      end

      verbose("Resolved #{ server_host } from DNS")
      return Addressable::URI.parse("https://#{ server_host }:443")
  end

  def self.read_apiserver_file
    server = File.open("/etc/puavo/apiserver").read.strip
    if /^https?:\/\//.match(server)
      return server
    else
      return "https://#{ server }"
    end
  end

  def initialize(_options={})
    @options = _options.dup
    @servers = []
    @headers = {
      "user-agent" => "puavo-rest-client"
    }
    @header_overrides = (_options[:headers] || {}).dup

    if @options[:puavo_domain].nil?
      @options[:puavo_domain] = File.open("/etc/puavo/domain").read.strip
      verbose("Using puavo domain '#{ @options[:puavo_domain] }' from /etc/puavo/domain")
    end

    if @options[:server]
      @servers = [
        :uri => Addressable::URI.parse(@options[:server]),
        :ssl_context => self.class.public_ssl
      ]
    else

      if @options[:dns] != :no
        begin
          @servers.push({
            :uri => Addressable::URI.parse(self.class.resolve_apiserver_dns(@options[:puavo_domain])),
            :ssl_context => self.class.custom_ssl
          })
        rescue ResolvFail => err
          verbose("DNS resolving failed: #{ err }")
          # Crash if only dns is allowed
          raise err if @options[:dns] == :only
        end
      end

      if @options[:dns] != :only
        begin
          @servers.push({
            :uri => Addressable::URI.parse(self.class.read_apiserver_file),
            :ssl_context => self.class.public_ssl
          })
        rescue Errno::ENOENT
          verbose("/etc/puavo/apiserver is missing. Using puavo domain instead")
          @servers.push({
            :uri => Addressable::URI.parse("https://#{ @options[:puavo_domain] }"),
            :ssl_context => self.class.public_ssl
          })
        end
      end

    end

    # Set request header to puavo domain. Using this we can make requests to
    # api.opinsys.fi with basic auth and get the correct organisation
    @headers["host"] = @options[:puavo_domain]


    # Force usage of custom ca_file if set
    if @options[:ca_file]
      @servers.each do |server|
        server[:ssl_context] = self.class.custom_ssl(@options[:ca_file])
      end
    end

    if @options[:port]
      @servers.each do |server|
        server[:uri].port = @options[:port]
      end
    end

    if @options[:scheme]
      @servers.each do |server|
        server[:uri].scheme = @options[:scheme]
      end
    end

    if @options[:auth] == :bootserver
      @headers["authorization"] = "Bootserver"
    end

    if @options[:auth] == :etc
      @options[:basic_auth] = {
        :user => File.open("/etc/puavo/ldap/dn").read.strip,
        :pass => File.open("/etc/puavo/ldap/password").read.strip
      }
      verbose("Using credendials (dn: #{ @options[:basic_auth][:user] }) from /etc/puavo/ldap/")
    end
  end

  def servers
    @servers.map{|s| s.to_s}
  end

  [:get, :post].each do |method|
    define_method(method) do |path, *args|
      previous_attempt = nil
      options = args.first || {}

      err = nil

      @servers.each do |server|
        uri = server[:uri].dup
        uri.path = path

        if uri.scheme == "https"
          options[:ssl_context] = server[:ssl_context]
        end

        if previous_attempt
          verbose "Attempting retry on fallback server"
          options[:headers] = (options[:headers] || {}).merge({
            "x-puavo-rest-client-previous-attempt" => previous_attempt
          })
        end

        verbose("#{ method.to_s.upcase } #{ uri }")

        res = nil
        begin
          res = do_request(uri.host, method, uri, options)
        rescue *RETRY_FALLBACK_EXCEPTIONS => _err
          previous_attempt = uri
          verbose("Request error: #{ _err }")
          raise _err if @options[:retry_fallback].nil?
          err = _err
        else
          return res
        end
      end

      raise err if err
    end
  end

  private

  def do_request(host, method, uri, options)
    res = client(uri.host).send(method, uri, options)
    verbose("Response headers")
    verbose_log_headers(res.headers)

    if !@options[:silent] && res.headers["x-puavo-rest-warn"]
      warn "puavo-rest-warn: #{ res.headers["x-puavo-rest-warn"] }"
    end

    verbose("Response HTTP status #{ res.status }")
    if !SUCCESS_STATUS_CODES.include?(res.code)
      raise BadStatusCode, res
    end
    return res
  end

  # http.rb client getter. Must be called for each request in order to get new
  # kerberos ticket since one ticket can be used only for  one request
  def client(host)
    headers = @headers.dup

    # Add custom header overrides given by the user
    headers.merge!(@header_overrides)

    http = HTTP.headers(headers)

    verbose("Request headers:")
    verbose_log_headers(headers)

    if @options[:timeout]
      timeout = @options[:timeout] / 3.0
      http = http.timeout(:global,
                          :write   => timeout,
                          :connect => timeout,
                          :read    => timeout)
    end

    if @options[:auth] == :kerberos
      gsscli = GSSAPI::Simple.new(host, "HTTP")
      token = gsscli.init_context(nil, :delegate => true)
      http = http.auth("Negotiate #{Base64.strict_encode64(token)}")
    end

    if @options[:basic_auth]
      http = http.basic_auth(@options[:basic_auth])
    end

    if @options[:location]
      http = http.follow
    end

    http
  end

end
