
# Various helper methods for puavo-ds scripts

# Assertive shell exec. Raises runtime error if given command does not exit
# with 0
def assert_exec(cmd)
  out = `#{ cmd }`
  if not $?.success?
    raise "Failed to execute '#{ cmd }'"
  end
  return out
end
