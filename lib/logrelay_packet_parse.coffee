
logRelayPacketParse = (data) ->
  packet = {}

  data.toString().split("\n").forEach (line) ->
    if not line then return
    if not line.match(/[.+:.+]/)
      console.error "UDP packet: bad line:", line
      return

    [k, v...] = line.split(":")
    # Restore value if it had colons
    v = v.join(":")

    # Turn values inside brackets [foo,bar] to arrays
    if match = v.match(/\[(.*)\]/)
      v = match[1].split(",")

    packet[k] = v

  return packet

module.exports = logRelayPacketParse
