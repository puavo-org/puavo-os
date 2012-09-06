require 'eventmachine'
require 'net/http'

module PacketRelay

  DEFAULT_INTERVAL = 5
  TARGET = URI("http://10.246.131.169:8081/log")

  def post_init
    puts "CREATING"
    @queue = []
    @interval = DEFAULT_INTERVAL

    @timer = EventMachine::PeriodicTimer.new(@interval) do
      STDERR.puts "Timer tick"
      send_packets
    end

  end

  def receive_data(data)
    return if data.nil?

    packet = {}

    data.split("\n").each do |item|
      next if item.empty?
      values = item.split ":"
      STDERR.puts values
      packet[values[0]] = values[1..-1].join(":")
    end

    STDERR.puts "Queueing #{ packet }"
    @queue.push({
      :packet => packet,
      :count => 0,
      :queue_date => Time.now
    })

    send_packets

  end

  def send_packets
    retry_send = []

    @queue.each do |data|

      STDERR.puts "Sending #{ data }"

      begin
        res = Net::HTTP.post_form TARGET, data[:packet]
        STDERR.puts "Sent", res
        @interval = DEFAULT_INTERVAL
      rescue Exception => e

        if @interval < 60*10
          @interval = @interval * 2
        end

        STDERR.puts "POST failed to #{ TARGET } because #{ e }. Interval is now #{ @interval  }"
        retry_send.push data
      end
    end

    @queue = retry_send
  end

end

EventMachine::run do
 EventMachine::open_datagram_socket "0.0.0.0", 1234, PacketRelay
end

