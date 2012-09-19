require 'eventmachine'
require 'socket'
require 'json'
require "pp"


RELAY_HOSTNAME = Socket.gethostname
PUAVO_DOMAIN = File.open("/etc/opinsys/desktop/puavodomain", "r").read.strip
DB_NAME = PUAVO_DOMAIN.gsub(/[^a-z0-9]/, "-")

UDP_PORT = 3858

INITIAL_INTERVAL = 2 # Time to wait in case of error (seconds)
MAX_INTERVAL = 60*10

# HTTP POST target
HOST = "10.246.133.138"
PORT = 8080
PATH = "/log"


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

module PacketRelay

  def post_init
    @queue = []
    @interval = INITIAL_INTERVAL
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
      log "WARNING: Packet has no type field"
      packet[:type] = "unknown"
    end

    send_packet packet

  end

  def send_packet(packet)

    if @error_state || @sending
      @queue.push packet
      log "Queueing packet. Queue size #{ @queue.size }. Interval is now #{ @interval }"
      return
    end

    log "Sending packet"

    @sending = true
    http = EventMachine::Protocols::HttpClient.request(
     :verb => "POST",
     :host => HOST,
     :port => PORT,
     :request => PATH,
     :contenttype => "application/json",
     :content => packet.to_json
    )

    http.errback do |*args|
      log "Sent failed. Response object: #{ args.pretty_inspect }"
      handle_error(packet)
    end

    http.callback do |res|
      if res[:status] == 200
        log "Packet sent ok"
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

    if @interval < MAX_INTERVAL
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
    @interval = INITIAL_INTERVAL
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

