
require "minitest/autorun"

require "./lib/tftpfilesender"



class DummyReader

  attr_accessor :files

  def initialize
    @files = {}
  end

  def read(name)
    if f =@files[name]
      return f
    else
      raise Errno::ENOENT
    end
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
        EM::stop_event_loop
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

        EM::stop_event_loop
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
        EM::stop_event_loop
      end

      fs.files["mod512"] = "X"*512*4
      sender.handle_get([
        TFTP::Opcode::RRQ,
        "mod512",
        "octet"
      ].pack("na*xa*x"))

    end
  end

  it "calls on_end on nonexistent files" do
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
          ["\x00\x05\x00\x01No found :(\x00", "127.0.0.1", 1234],
          sender.sent_packets.last
        )
        EM::stop_event_loop
      end

      sender.handle_get([
        TFTP::Opcode::RRQ,
        "notfound",
        "octet"
      ].pack("na*xa*x"))

    end
  end


  describe "extension" do

    describe "tsize" do
      it "sents oack for tsize extension" do
        fs = DummyReader.new
        ev_run DummyFileSender, "127.0.0.1", 1234, fs do |sender|

          sender.on_data do |data, ip, port|
            assert_equal(data, "\x00\x06tsize\x00700\x00")
            EM::stop_event_loop
          end

          fs.files["somefile"] = "X"*700
          sender.handle_get([
            TFTP::Opcode::RRQ,
            "somefile",
            "octet",
            "tsize",
            "0"
          ].pack("na*xa*xa*xa*x"))

        end
      end
    end


    describe "blksize" do
      it "sents oack for block extension" do
        fs = DummyReader.new
        ev_run DummyFileSender, "127.0.0.1", 1234, fs do |sender|

          sender.on_data do |data, ip, port|
            assert_equal(data, "\x00\x06blksize\x0010\x00")
            EM::stop_event_loop
          end

          fs.files["somefile"] = "X"*700
          sender.handle_get([
            TFTP::Opcode::RRQ,
            "somefile",
            "octet",
            "blksize",
            "10",
            "0"
          ].pack("na*xa*xa*xa*x"))

        end
      end

      it "sents blksize sized packages" do
        fs = DummyReader.new
        ev_run DummyFileSender, "127.0.0.1", 1234, fs do |sender|

          handlers = [
            lambda do |data|
              sender.handle_ack([
                TFTP::Opcode::ACK, 0
              ].pack("nn"))
            end,

            lambda do |data|
              assert_equal(
                "\x00\x03\x00\x01XXXXXXXXXX",
               data
              )
              _, num = data.unpack("nn")
              puts "SENDING ACK TO SERVER #{ num }"
              sender.handle_ack([
                TFTP::Opcode::ACK,
                num
              ].pack("nn"))
            end,

            lambda do |data|
              assert_equal(
                "\x00\x03\x00\x02XX",
               data
              )
              _, num = data.unpack("nn")
              puts "SENDING ACK TO SERVER #{ num }"
              sender.handle_ack([
                TFTP::Opcode::ACK,
                num
              ].pack("nn"))
            end,
          ]

          sender.on_end do
            EM::stop_event_loop
          end

          count = -1

          sender.on_data do |data, ip, port|
            count += 1
            if h = handlers[count]
              h.call data
            end
          end

          fs.files["blksizetest"] = "X"*12
          sender.handle_get([
            TFTP::Opcode::RRQ,
            "blksizetest",
            "octet",
            "blksize",
            "10",
            "0"
          ].pack("na*xa*xa*xa*x"))

        end
      end

    end


  end

  it "resends package if I send ack for previous package" do
    fs = DummyReader.new
    ev_run DummyFileSender, "127.0.0.1", 1234, fs do |sender|

      handlers = [
        lambda do |data|
          sender.handle_ack([
            TFTP::Opcode::ACK, 1
          ].pack("nn"))
        end,

        lambda do |data|
          assert_equal(
            "\x00\x03\x00\x02" + "Y"*(512),
            data
          )
          sender.handle_ack([
            TFTP::Opcode::ACK, 1
          ].pack("nn"))
        end,

        lambda do |data|
          assert_equal(
            "\x00\x03\x00\x02" + "Y"*(512),
            data
          )
          EM::stop_event_loop
        end
      ]

      count = -1
      sender.on_data do |data, ip, port|
        count += 1
        handlers[count].call data
      end

      fs.files["file"] = "X"*512 + "Y"*520
      sender.handle_get([
        TFTP::Opcode::RRQ,
        "file",
        "octet"
      ].pack("na*xa*x"))

    end
  end
end

