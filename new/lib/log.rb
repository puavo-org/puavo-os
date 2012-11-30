
def log(*args)
  puts(*args)
end

def warn(*args)
  args[0] = "WARN: " + args[0]
  puts(*args)
end

def debug(*args)
  if $tftp_debug
    args[0] = "DEBUG: " + args[0]
    puts(*args)
  end
end

