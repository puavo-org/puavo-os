module Puavo

  def self.assert_exec(cmd)
    out = `#{ cmd }`
    if not $?.success?
      raise "Failed to execute '#{ cmd }'"
    end
    return out.to_s.strip
  end

  def self.resolve_api_server!
    # TODO: implement in ruby
    out = assert_exec("puavo-resolve-api-server")
    if out == ""
      raise "Got empty response from puavo-resolve-api-server"
    end
    return out
  end

end
