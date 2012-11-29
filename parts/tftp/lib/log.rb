
def log(*args)
  puts(*args)
end

def error(*args)
  args[0] = "ERROR: " + args[0]
  puts(*args)
end

def debug(*args)
  # args[0] = "DEBUG: " + args[0]
  # puts(*args)
end
