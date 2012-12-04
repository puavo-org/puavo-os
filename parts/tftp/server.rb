#!/usr/bin/ruby1.9.3

require "etc"
require "yaml"

$LOAD_PATH.unshift( File.dirname(__FILE__) )

require "puavo-tftp/log"
require "puavo-tftp/tftpserver"
require "puavo-tftp/cachedfilereader"

require 'optparse'


options = {
  :port => 69,
  :group => "nogroup",
  :root => Dir.pwd
}

configuration = YAML.load_file('config.yml')
options.merge!( configuration ) if configuration

OptionParser.new do |opts|
  opts.banner = "Usage: [sudo] ./server.rb [options]"

  opts.on("-r", "--root PATH", String, "Serve files from directory.") do |v|
    if v[0] == "/"
      options[:root] = v
    else
      options[:root] = File.join(Dir.pwd, v)
    end
  end

  opts.on("-u", "--user USER", String, "Drop to user.") do |v|
    options[:user] = v
  end

  opts.on("-g", "--group GROUP", String, "Drop to group. Default #{ options[:group] }") do |v|
    options[:group] = v
  end

  opts.on("--verbose", "Print more debugging stuff.") do |v|
    $tftp_debug = true
  end

  opts.on("-p", "--port PORT", "Listen on port.") do |v|
    options[:port] = v.to_i
  end

end.parse!




EventMachine::run do
  EventMachine::open_datagram_socket(
    "0.0.0.0",
    options[:port],
    TFTP::Server,
    CachedFileReader.new(options[:root]),
    options
  ) do

    log "Serving files from #{ options[:root] }"
    log "Listening on #{ options[:port] }"

    if Process.uid == 0
      if not options[:user]
        log "ERROR: Started as root, but no --user is defined."
        Process.exit 1
      end
      Process.initgroups(options[:group], Etc.getgrnam(options[:group]).gid)
      Process::Sys.setgid(Etc.getgrnam(options[:group]).gid)
      Process::Sys.setuid(Etc.getpwnam(options[:user]).uid)
      log "Changed to uid #{ Process.uid } and gid #{ Process.gid }"
    end

  end
end
