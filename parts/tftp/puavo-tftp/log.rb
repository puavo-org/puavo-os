
def log(*args)
  args[0] = Time.now.to_s + " " + args[0]
  $stderr.puts(*args)
end

def warn(*args)
  args[0] = "WARN: " + args[0]
  log(*args)
end

if $tftp_debug
  def debug(*args)
      args[0] = "DEBUG: " + args[0]
      log(*args)
    end
else
  def debug(*args)
  end
end

