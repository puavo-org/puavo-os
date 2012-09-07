require 'eventmachine'
require 'json'
require "pp"


UDP_PORT=3858

INITIAL_INTERVAL=2 # Time to wait in case of error (seconds)
MAX_INTERVAL=60*10

# HTTP POST target
HOST = "localhost"
PORT = 8080
PATH = "/log"


def log(*args)
  STDERR.puts(*args)
end

module PacketRelay

  def post_init
    @queue = []
    @interval = INITIAL_INTERVAL
  end

  def receive_data(data)
    return if data.nil?

    message = {}

    data.split("\n").each do |item|
      next if item.empty?
      values = item.split ":"
      message[values[0]] = values[1..-1].join(":")
    end

    send_packet({
      :message => message,
      :count => 0,
      :queue_date => Time.now
    })

  end

  def send_packet(packet)

    if @error_state || @sending
      log "Queueing packet #{ packet.to_json }"
      @queue.push packet
      return
    end

    log "Sending #{ packet[:message].to_json }"

    @sending = true
    http = EventMachine::Protocols::HttpClient.request(
     :verb => "POST",
     :host => HOST,
     :port => PORT,
     :request => PATH,
     :contenttype => "application/json",
     :content => packet[:message].to_json
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

    if @interval < 60*10
      @interval = @interval*2
    end

    log "Sleeping #{ @interval } seconds until resend"

    EventMachine::Timer.new(@interval) do
      log "Resending from timer #{ packet.to_json }"
      @error_state = false
      send_packet(packet)
    end
  end

  def handle_ok
    @sending = false
    @interval = INITIAL_INTERVAL
    next_packet = @queue.shift
    if not next_packet.nil?
      log "Sending from queue #{ next_packet.to_json }"
      send_packet(next_packet)
    end
  end

end

EventMachine::run do
 EventMachine::open_datagram_socket "0.0.0.0", UDP_PORT, PacketRelay
 log "Now listening on UDP port #{ UDP_PORT }"
end

