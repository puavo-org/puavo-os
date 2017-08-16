require "net/http"
require "socket"
require "fluent/plugin/out_forward"

module PuavoFluent
begin
  IMAGE_VERSION = File.open("/etc/ltsp/this_ltspimage_name", "r") do |f|
    f.read
  end.strip
rescue Errno::ENOENT
  IMAGE_VERSION = ""
end

class PuavoWrapper
  Fluent::Plugin.register_output('puavo', self)
  attr_accessor :plugin

  def read_puavo_file(name)
    File.open("/etc/puavo/#{ name }", "r"){ |f| f.read }.strip
  end

  def configure(conf)
    conf["puavo_hosttype"] ||= read_puavo_file "hosttype"
    conf["puavo_hostname"] ||= read_puavo_file "hostname"
    conf["puavo_domain"] ||= read_puavo_file "domain"

    if ["laptop", "bootserver"].include?(conf["puavo_hosttype"])
      conf["puavo_ldap_dn"] ||= read_puavo_file "ldap/dn"
      conf["puavo_ldap_password"] ||= read_puavo_file "ldap/password"
      @plugin = RestOut.new
    else
      @plugin = AutoForward.new
    end

    $log.info "Puavo: I'm a #{ conf["puavo_hosttype"] } so I'm using #{ @plugin.class }"

    conf.elements.select do |el|
      if el.name == "device"
        el.arg.split("|").include?(conf["puavo_hosttype"])
      end
    end.each do |customizations|
      # merge! is not working here for some reason
      customizations.each{ |k,v| conf[k] = v }
    end
    @plugin.configure(conf)
    $log.info "flush_interval is #{ conf["flush_interval"] }"
  end

  def inject_device_source(record)
    record["meta"] ||= {}
    record["meta"]["timestamp"] ||= Time.now.to_s
    record["meta"]["device_source"] ||= {
      "fqdn" => Socket.gethostbyname(Socket.gethostname).first,
      "host_type" => config["puavo_hosttype"],
      "hostname" => config["puavo_hostname"],
      "organisation_domain" => config["puavo_domain"],
      "image_version" => IMAGE_VERSION
    }
  end

  def method_missing(name, *args)
    if @plugin.nil?
      raise "@plugin not set! Cannot call #{ name.inspect } with #{ args.inspect }"
    end
    @plugin.send(name, *args)
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      inject_device_source(record)
    end
    @plugin.emit(tag, es, chain)
  end

end

class AutoForward < Fluent::ForwardOutput

  def configure(conf)

    conf.elements.each do |el|
      if el.name == "server" && el["host"].to_s.strip == ""
        el["host"] = resolve_bootserver_hostname
        $log.info "Forwarding host was resolved to #{ el["host"] } for #{ el.name }"
      end
    end

    super(conf)
  end

  def resolve_bootserver_hostname
    api_server = `puavo-resolve-api-server`
    if not $?.success?
      raise Fluent::ConfigError, "Failed to execute puavo-resolve-api-server"
    end

    host = URI.parse(api_server).host
    if host.to_s.strip == ""
      raise Fluent::ConfigError, "Empty response from puavo-resolve-api-server"
    end
    host
  end

end

class RestOut < Fluent::BufferedOutput

  def configure(conf)
    @port = 443
    @host = "api.opinsys.fi"
    # max json records to send in single http post

    @host = conf["rest_host"] if conf["rest_host"]
    @port = conf["rest_port"] if conf["rest_port"]

    $log.info "Rest is using #{ @host }:#{ @port }"
    super(conf)
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def http_write(chunk)
    path = "/v3/fluent"
    req = Net::HTTP::Post.new(path, "Content-Type" => "application/x-msgpack")
    req.basic_auth @config["puavo_ldap_dn"], @config["puavo_ldap_password"]

    http = Net::HTTP.new(@host, @port)
    http.use_ssl = @port == 443

    http.read_timeout = 300 # 5 min

    $log.info "Sending #{ chunk.size } bytes using http to #{ @host }:#{ @port }#{ path }"

    res = http.request(req, chunk)
    if res.code != "200"
      msg = "Bad HTTP Response #{ res.code }: #{ res.body[0...500] }"
      $log.error msg
      raise msg
    end

    $log.info "Sent ok! #{ res } #{ res.code } #{ res.body }"
  end

  def write(chunk)
    http_write(chunk.read)
  end
end

end
