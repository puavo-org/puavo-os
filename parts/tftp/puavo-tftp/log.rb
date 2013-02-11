
def log(*args)
  args[0] = Time.now.to_s + " " + args[0]
  $stderr.puts(*args)
end

def warn(*args)
  args[0] = "WARN: " + args[0]
  log(*args)
end

def debug(*args)
  if $tftp_debug
    args[0] = "DEBUG: " + args[0]
    log(*args)
  end
end

