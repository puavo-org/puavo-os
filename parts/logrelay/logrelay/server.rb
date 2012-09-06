require 'eventmachine'
require 'json'
require "pp"

pp EventMachine::Protocols::HttpClient

def log(*args)
  STDERR.puts(*args)
end

module PacketRelay

  DEFAULT_INTERVAL = 2
  HOST = "10.246.131.169"
  PORT = 8081
  PATH = "/log"

  def post_init
    @queue = []
    @interval = DEFAULT_INTERVAL
  end

  def receive_data(data)
    return if data.nil?

    packet = {}

    data.split("\n").each do |item|
      next if item.empty?
      values = item.split ":"
      packet[values[0]] = values[1..-1].join(":")
    end

    send_packet({
      :packet => packet,
      :count => 0,
      :queue_date => Time.now
    })

  end

  def send_packet(next_packet)

    if @error_state || @sending
      log "Queueing packet #{ next_packet.to_json }"
      @queue.push next_packet
      return
    end

    log "Sending #{ next_packet[:packet].to_json }"

    @sending = true
    http = EventMachine::Protocols::HttpClient.request(
     :verb => "POST",
     :host => PacketRelay::HOST,
     :port => PacketRelay::PORT,
     :request => PacketRelay::PATH,
     :contenttype => "application/json",
     :content => next_packet[:packet].to_json
    )

    http.comm_inactivity_timeout = 5

    # EventMachine::Timer.new(4) do
    #   log "Closing connection"
    #   http.close_connection
    # end


    http.errback do |*args|
      pp "ERR", args
    end

    http.callback do |res|
      log "RES:#{ res[:status] }"
      @sending = false

      if res[:status] == 200
        @interval = DEFAULT_INTERVAL
        next_packet = @queue.shift
        if not next_packet.nil?
          log "Sending from queue #{ next_packet.to_json }"
          send_packet(next_packet)
        end
      else
        @error_state = true

        if @interval < 60*10
          @interval = @interval*2
          log "Interval is now #{ @interval }"
        end

        EventMachine::Timer.new(@interval) do
          log "Resending from timer #{ next_packet.to_json }"
          @error_state = false
          send_packet(next_packet)
        end
      end

    end
  end
end

EventMachine::run do
 EventMachine::open_datagram_socket "0.0.0.0", 1234, PacketRelay
end

