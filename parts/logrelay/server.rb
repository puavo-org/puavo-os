require "eventmachine"
require "etc"
require "socket"
require "json"
require "pp"

def log(*args)

  args = args.map do |a|
    if a.class != String
      a.pretty_inspect.strip
    else
      a
    end
  end

  args.unshift Time.now.to_s
  msg = args.join(" ")
  STDERR.puts(msg)
end


## Configuration

# User name and group this process should run as
USER = "epeli"
GROUP = "nogroup"

# UDP port this process listens to
UDP_PORT = 3858

# Time to wait in case of error (seconds)
INITIAL_INTERVAL = 2

# Interval increases until this point
MAX_INTERVAL = 60*10

# HTTP POST target for log data
HOST = "10.246.133.138" # prod
PORT = 8080 # prod
PATH = "/log"

HTTP_REQUEST_TIMEOUT = 10

# Collect rest of the configuration from the server

log "Starting with uid #{ Process.uid } and gid #{ Process.gid }"

USERNAME = File.open("/etc/puavo/ldap/dn", "r").read.strip
PASSWORD = File.open("/etc/puavo/ldap/password", "r").read.strip

Process::Sys.setgid(Etc.getgrnam(GROUP).gid)
Process::Sys.setuid(Etc.getpwnam(USER).uid)

log "Dropped to uid #{ Process.uid } and gid #{ Process.gid }"

PUAVO_DOMAIN = File.open("/etc/opinsys/desktop/puavodomain", "r").read.strip
RELAY_HOSTNAME = Socket.gethostname





module PacketRelay

  def post_init
    @queue = []
  end

  def receive_data(data)
    return if data.nil?

    packet = {
      :relay_hostname => RELAY_HOSTNAME,
      :relay_puavo_domain => PUAVO_DOMAIN,
      :relay_timestamp => Time.now.to_i
    }

    data.split("\n").each do |item|
      next if item.empty?
      values = item.split ":"
      packet[values[0].to_sym] = values[1..-1].join(":")
    end

    if packet[:type].nil?
      log "WARNING: Packet has no type field", packet[:relay_timestamp]
      packet[:type] = "unknown"
    end

    send_packet packet

  end

  def send_packet(packet)

    if @error_state || @sending
      @queue.push packet
      log "Queueing packet. Queue size #{ @queue.size }. Interval is now #{ @interval }s.", "Packet:",  packet[:relay_timestamp]
      return
    end

    log "Sending packet", packet[:relay_timestamp]

    @sending = true
    http = EventMachine::Protocols::HttpClient.request(
     :verb => "POST",
     :host => HOST,
     :port => PORT,
     :request => PATH,
     :contenttype => "application/json",
     :content => packet.to_json,
     :basic_auth => {
      :username => USERNAME,
      :password => PASSWORD
     }
    )
    timeout = false

    # XXX: Fuck. Manually implement timeout for http request.
    timeout_timer = EventMachine::Timer.new(HTTP_REQUEST_TIMEOUT) do
      timeout = true
      log "WARNING: Request timeout for packet", packet[:relay_timestamp]

      # XXX: How to actually cancel the request?
      http.close_connection

      handle_error(packet)
    end

    http.errback do |*args|
      next if timeout
      timeout_timer.cancel()
      log "Sent failed. Response object: #{ args.pretty_inspect }"
      handle_error(packet)
    end

    http.callback do |res|
      next if timeout
      timeout_timer.cancel()
      if res[:status] == 200
        log "Packet sent ok", packet[:relay_timestamp]
        handle_ok
      else
        log "Sent failed. Status code #{ res[:status] }"
        handle_error(packet)
      end
    end


  end

  def handle_error(packet)
    @sending = false
    @error_state = true

    if @interval.nil?
      @interval = INITIAL_INTERVAL
    elsif @interval < MAX_INTERVAL
      @interval = @interval*2
    end

    log "Sleeping #{ @interval } seconds until resend"

    EventMachine::Timer.new(@interval) do
      log "Resending from timer"
      @error_state = false
      send_packet(packet)
    end
  end

  def handle_ok
    @sending = false
    @interval = nil
    next_packet = @queue.shift
    if not next_packet.nil?
      log "Sending from queue"
      send_packet(next_packet)
    end
  end

end

EventMachine::run do
 EventMachine::open_datagram_socket "0.0.0.0", UDP_PORT, PacketRelay
 log "Now listening on UDP port #{ UDP_PORT }"
end

