
net = require "net"
{expect} = require "chai"

JSONStream = require "json-stream"
Pinger = require "../lib/pinger"

describe "Pinger", ->

  it "write ping messages", (done) ->
    jsonStream = new JSONStream()
    tcpMockStream = {
      write: (msg) ->
        expect(JSON.parse(msg)).to.deep.eq({
          type: "internal"
          event: "ping"
        })
        done()
    }

    pinger = new Pinger(tcpMockStream, jsonStream, 100, 100)
    pinger.ping()


  it "timeout if no pong is received", (done) ->
    jsonStream = new JSONStream()
    tcpMockStream = write: (msg) ->

    pinger = new Pinger(tcpMockStream, jsonStream, 100, 10)
    pinger.ping()

    pinger.on "timeout", done

  it "timeout if no pong is received", (done) ->
    jsonStream = new JSONStream()
    tcpMockStream = write: (msg) ->
      jsonStream.emit "data", {
        type: "internal"
        event: "pong"
      }

    pinger = new Pinger(tcpMockStream, jsonStream, 100, 10)
    pinger.ping()

    pinger.on "timeout", ->
      done new Error "pong timeout"

    setTimeout done, 20

  it "pinging is continuous", (done) ->
    jsonStream = new JSONStream()
    count = 5
    tcpMockStream = write: (msg) ->
      count -= 1
      if count is 0
        done()

      jsonStream.emit "data", {
        type: "internal"
        event: "pong"
      }

    pinger = new Pinger(tcpMockStream, jsonStream, 5, 5)
    pinger.ping()

  it "pinging can be stopped", (done) ->
    jsonStream = new JSONStream()
    count = 6
    tcpMockStream = write: (msg) ->
      count -= 1

      if count is 3
        pinger.stop()
        setTimeout done, 100

      if count is 0
        done new Error "ping was not stopped"

      jsonStream.emit "data", {
        type: "internal"
        event: "pong"
      }

    pinger = new Pinger(tcpMockStream, jsonStream, 5, 5)
    pinger.ping()
