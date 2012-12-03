
require "minitest/autorun"

require "./lib/tftpfilesender"

EV = EventMachine


class DummyReader

  attr_accessor :files

  def initialize
    @files = {}
  end

  def read(name)
    @files[name]
  end

end

class DummyFileSender < TFTP::FileSender

  attr_reader :sent_packets

  def initialize(*args)
    super(*args)
    @sent_packets = []
  end

  def send_datagram(*args)
    @sent_packets.push args
  end

end

def ev_run(*args)
  EventMachine::run do
    yield EventMachine::open_datagram_socket(
      "127.0.0.1",
      0,
      *args
    )
  end
end

describe TFTP::FileSender do

  it "sends small file in one package" do
    fs = DummyReader.new
    ev_run DummyFileSender, "127.0.0.1", 1234, fs do |sender|
      sender.on_data do |data, ip, port|
          assert_equal(
            data,
            "\x00\x03\x00\x01small content"
          )
        EV::stop_event_loop
      end

      fs.files["small"] = "small content"
      sender.handle_get([
        TFTP::Opcode::RRQ,
        "small",
        "octet"
      ].pack("na*xa*x"))
    end
  end

  it "sends larger file in two packages" do
    fs = DummyReader.new
    ev_run DummyFileSender, "127.0.0.1", 1234, fs do |sender|

      sender.on_data do |data, ip, port|
        _, num = data.unpack("nn")

        sender.handle_ack([
          TFTP::Opcode::ACK,
          num
        ].pack("nn"))
      end

      sender.on_end do
        assert_equal(
          "\x00\x03\x00\x01" + "X"*512,
          sender.sent_packets[0][0]
        )

        assert_equal(
          "\x00\x03\x00\x02" + "X"*(600-512),
          sender.sent_packets[1][0]
        )

        EV::stop_event_loop
      end

      fs.files["larger"] = "X"*600
      sender.handle_get([
        TFTP::Opcode::RRQ,
        "larger",
        "octet"
      ].pack("na*xa*x"))

    end
  end

  it "sends an empty packge as last packet when sending mod 512 file" do
    fs = DummyReader.new
    ev_run DummyFileSender, "127.0.0.1", 1234, fs do |sender|

      sender.on_data do |data, ip, port|
        _, num = data.unpack("nn")
        sender.handle_ack([
          TFTP::Opcode::ACK,
          num
        ].pack("nn"))
      end

      sender.on_end do
        assert_equal(
          ["\x00\x03\x00\x05", "127.0.0.1", 1234],
          sender.sent_packets.last
        )
        EV::stop_event_loop
      end

      fs.files["mod512"] = "X"*512*4
      sender.handle_get([
        TFTP::Opcode::RRQ,
        "mod512",
        "octet"
      ].pack("na*xa*x"))

    end
  end

end

