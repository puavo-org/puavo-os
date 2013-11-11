require "net/http"

module PuavoFluent
  HOST_TYPE = File.open("/etc/puavo/hosttype", "r"){ |f| f.read }.strip
  HOSTNAME = File.open("/etc/puavo/hostname", "r"){ |f| f.read }.strip
  ORGANISATION_DOMAIN = File.open("/etc/puavo/domain", "r"){ |f| f.read }.strip
  TOP_DOMAIN = File.open("/etc/puavo/topdomain", "r"){ |f| f.read }.strip
  LDAP_DN = File.open("/etc/puavo/ldap/dn", "r"){ |f| f.read }.strip
  LDAP_PASSWORD = File.open("/etc/puavo/ldap/password", "r"){ |f| f.read }.strip

class PuavoWrapper
  Fluent::Plugin.register_output('puavo', self)

  def initialize(*args)
    if ["laptop", "bootserver"].include?(HOST_TYPE)
      @plugin = RestOut.new(*args)
    else
      @plugin = AutoForward.new(*args)
    end

    puts "#"*80
    puts "Puavo: I'm a #{ HOST_TYPE } so I'm using #{ @plugin.class }"
    puts "#"*80
    super(*args)
  end

  def configure(conf)
    if not conf["flush_interval"]
      conf["flush_interval"] = @plugin.default_flush_interval
    end

    @plugin.configure(conf)
  end

  def inject_device_source(record)
    record["meta"] ||= {}
    record["meta"]["device_source"] ||= {
      "host_type" => HOST_TYPE,
      "hostname" => HOSTNAME,
      "organisation_domain" => ORGANISATION_DOMAIN
    }
  end


  def method_missing(name, *args)
    puts "#"*80
    puts "Proxy call to #{ @plugin.class }##{ name } with #{ args.inspect }"
    puts "#"*80
    @plugin.send(name, *args)
  end

  def emit(tag, es, chain)
    es.each do |time, record|
      inject_device_source(record)
    end
    $log.info "emitting #{ tag }"
    @plugin.emit(tag, es, chain)
  end

end

class WriteFail < Exception; end

class AutoForward < Fluent::ForwardOutput

  def default_flush_interval
    "5s"
  end

  def configure(conf)

    conf.elements.each do |el|
      if el.name == "server" && el["name"] == "bootserver"
        el["host"] = resolve_bootserver_hostname
        $log.info "bootserver was resolved to #{ el["host"] }"
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

  def initialize(*args)
    @port = 443
    @host = "api.#{ TOP_DOMAIN }"
    super(*args)
  end

  def configure(conf)
    if conf["rest_host"]
      @host = conf["rest_host"]
    end

    if conf["rest_port"]
      @port = conf["rest_port"]
    end

    $log.info "Rest is using #{ @host }:#{ @port }"
    super(conf)
  end

  def default_flush_interval
    "60s"
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def write(chunk)
    tags = {}

    chunk.msgpack_each do |(tag,time,record)|
      tags[tag] ||= []
      record["_timestamp"] = time.to_i
      tags[tag].push(record)
    end

    tags.each do |tag, records|
      path = "/v3/fluent/#{ tag }"
      req = Net::HTTP::Post.new(path, "Content-Type" => "application/json")
      req.basic_auth LDAP_DN, LDAP_PASSWORD

      http = Net::HTTP.new(@host, @port)
      http.use_ssl = @port == 443

      $log.info "Sending #{ records.size } #{ tag } records to #{ @host }:#{ @port }#{ path }"

      res = http.request(req, records.to_json)
      if res.code != "200"
        msg = "Bad HTTP Response #{ res.code.inspect }: #{ res.body }"
        $log.error msg
        raise WriteFail, msg
      end
      $log.info "Sent ok! #{ res } #{ res.code } #{ res.body }"
    end

  end
end

end
