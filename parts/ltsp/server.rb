#!/usr/bin/ruby1.9.3

require "./lib/log"
require "./lib/tftpserver"

require 'optparse'

options = {
  :port => 69,
  :root => Dir.pwd
}

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-m", "--mount PATH", String, "Server files from directory") do |v|
    if v[0] == "/"
      options[:root] = v
    else
      options[:root] = File.join(Dir.pwd, v)
    end
  end

  opts.on("-p", "--porti PORT", "Listen on port") do |v|
    options[:port] = v.to_i
  end

end.parse!


EventMachine::run do
  log "Serving files from #{ options[:root] }"
  log "Listening on #{ options[:port] }"
  EventMachine::open_datagram_socket(
    "0.0.0.0",
    options[:port],
    TFTP::Server,
    options[:root]
  )
end
