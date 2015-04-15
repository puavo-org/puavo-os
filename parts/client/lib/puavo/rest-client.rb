
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

  def self.verbose(*msg)
    if $puavo_rest_client_verbose
      STDERR.puts(*msg)
    end
  end

  def verbose(*msg)
    self.class.verbose(*msg)
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

  class ResolvFail < Exception
  end

  def self.resolve_apiserver_dns(puavo_domain)

      res = Resolv::DNS.open do |dns|
        dns.getresources(
          "_puavo-api._tcp.#{ puavo_domain }",
          Resolv::DNS::Resource::IN::SRV
        )
      end

      if res.nil? || res.empty?
        raise ResolvFail, "Empty response"
      end

      server_host = res.first.target.to_s
      if !server_host.end_with?(puavo_domain)
        raise ResolvFail, "Invalid value. #{ server_host } does not match with requested puavo domain #{ puavo_domain }. Using master puavo-rest as fallback"
      end

      verbose("Resolved to bootserver puavo-rest #{ server_host }")
      return "https://#{ server_host }:443"
  end

  def read_apiserver_file
    server = File.open("/etc/puavo/apiserver").read.strip
    if !server.start_with?("http")
      raise "/etc/puavo/apiserver must have a protocol prefix"
    end
  end

  def initialize(_options={})
    @options = _options.dup
    @headers = {
      "User-Agent" => "puavo-rest-client"
    }
    @header_overrides = (_options[:headers] || {}).dup

    if @options[:puavo_domain].nil?
      verbose("Using puavo domain from /etc/puavo/domain")
      @options[:puavo_domain] = File.open("/etc/puavo/domain").read.strip
    end

    # Auto select apiserver if not manually set
    if @options[:apiserver].nil?

      if @options[:dns] != :no
        begin
          @options[:apiserver] = self.class.resolve_apiserver_dns(@options[:puavo_domain])
          @options[:ssl_context] = self.class.custom_ssl
        rescue ResolvFail => err
          # Crash if only dns is allowed
          raise err if @options[:dns] == :only
        end
      end

      begin
        @options[:apiserver] = read_apiserver_file()
      rescue Errno::ENOENT
      end
    end

    if @options[:apiserver]
      uri = Addressable::URI.parse(@options[:apiserver])
      @options[:scheme] ||= uri.scheme
      @options[:port] ||= uri.port
      @options[:server_host] ||= uri.host
    end

    @options[:scheme] ||= "https"

    if @options[:port].nil?
      if @options[:scheme] == "https"
        @options[:port] = 443
      elsif @options[:scheme] == "http"
        @options[:port] = 80
      else
        raise "Invalid protocol #{ @options[:scheme] }"
      end
    end

    # Set request header to puavo domain. Using this we can make requests to
    # api.opinsys.fi with basic auth and get the correct organisation
    @headers["Host"] = @options[:puavo_domain]


    # Force usage of custom ca_file if set
    if @options[:ca_file] && @options[:scheme] == "https"
      @options[:ssl_context] = self.class.custom_ssl(@options[:ca_file])
    end

    # Use puavo domain as the final fallback for server host
    @options[:server_host] ||= @options[:puavo_domain]

    # And public ssl for ssl fallback
    if @options[:scheme] == "https"
      @options[:ssl_context] ||= self.class.public_ssl
    end

    if @options[:auth] == :bootserver
      @headers["Authorization"] = "Bootserver"
    end

    if @options[:auth] == :etc
      verbose("Using credendials from /etc/puavo/ldap/")
      @options[:basic_auth] = {
        :user => File.open("/etc/puavo/ldap/dn").read.strip,
        :pass => File.open("/etc/puavo/ldap/password").read.strip
      }
    end
  end

  def to_full_url(path)
    "#{ @options[:scheme] }://#{ @options[:server_host] }:#{ @options[:port] }#{ path }"
  end

  def get(path)
    url = to_full_url(path)
    verbose("GET #{ url }")
    res = client.get url
    verbose("HTTP STATUS #{ res.status }")
    return res
  end

  private

  # http.rb client getter. Must be called for each request in order to get new
  # kerberos ticket since one ticket can be used only for  one request
  def client
    headers = @headers.dup
    _client = HTTP::Client.new(:ssl_context => @options[:ssl_context])

    if @options[:auth] == :kerberos
      gsscli = GSSAPI::Simple.new(@options[:server_host], "HTTP")
      token = gsscli.init_context(nil, :delegate => true)
      headers["Authorization"] = "Negotiate #{Base64.strict_encode64(token)}"
    end

    # Add custom header overrides given by the user
    headers.merge!(@header_overrides)

    _client = _client.with_headers(headers)
    verbose("REQUEST HEADERS: #{ headers.inspect }")

    if @options[:basic_auth]
      _client = _client.basic_auth(@options[:basic_auth])
    end

    return _client
  end
end
