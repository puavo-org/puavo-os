
assert = require "assert"
dgram = require "dgram"
express = require "express"
JSONStream = require "json-stream"
net = require "net"
Q = require "q"
request = require "request"

createServer = require "../lib/server"

PORT = process.env.TEST_PORT or 3253
TCP_PORT = PORT + 1
UDP_PORT = PORT + 2

uri = (p) -> "http://localhost:#{ PORT }#{ p }"

sendUdp = (msg) ->
    c = dgram.createSocket("udp4")
    b = new Buffer(msg)
    c.send b, 0, b.length, UDP_PORT, "localhost", (err) ->
        throw err if err

describe "Server", ->

    beforeEach (done) ->
        @server = createServer(
            tcpPort: TCP_PORT
            udpPort: UDP_PORT
            relayHostname: "test-hostname"
            puavoDomain: "test-puavo-domain"
            targetUrl: uri "/log"
            pingInterval: 100
            pingTimeout: 200
        )

        @http = express()
        @http.use(express.bodyParser())
        @_http = @http.listen PORT, (err) =>
            throw err if err
            @server.listening.done -> done()


    afterEach (done) ->
        @_http.close => @server.close().done -> done()

    describe "UDP", ->

        beforeEach (done) ->
            @http.post "/log", (req, res) =>
                @body = req.body
                res.end("ok")
                done()
            sendUdp("foo:bar")

        it "sets given value", ->
            assert.equal @body.foo, "bar"

        it "sets relay_hostname", ->
            assert.equal @body.relay_hostname, "test-hostname"

        it "sets relay_puavo_domain", ->
            assert.equal @body.relay_puavo_domain, "test-puavo-domain"

        it "sets timestamp", ->
            stamp = parseInt(@body.relay_timestamp, 10)
            assert stamp
            assert stamp <= Date.now()

    describe "TCP", ->

        it "gets ping messages", (done) ->
            c = net.createConnection TCP_PORT, (err) ->
                throw err if err
                c.pipe(JSONStream()).on "data", (packet) ->
                    if packet.event is "ping"
                        c.end()
                        done()

        describe "JSON bootend message", ->

            beforeEach (done) ->
                @http.post "/log", (req, res) =>
                    @body = req.body
                    res.end("ok")
                    done()

                @c = net.createConnection TCP_PORT, (err) =>
                    @c.write(JSON.stringify(
                        type: "desktop"
                        event: "bootend"
                    ) + "\n")

            it "sets event type", ->
                assert.equal @body.type, "desktop"
                assert.equal @body.event, "bootend"

            it "sets relay_hostname", ->
                assert.equal @body.relay_hostname, "test-hostname"

            it "sets relay_puavo_domain", ->
                assert.equal @body.relay_puavo_domain, "test-puavo-domain"

            it "sets timestamp", ->
                stamp = parseInt(@body.relay_timestamp, 10)
                assert stamp
                assert stamp <= Date.now()

        it "gets JSON shutdown message", (done) ->

            @http.post "/log", (req, res) =>
                res.end("ok")
                if req.body.event is "shutdown"
                    done()
            @tcp = net.createConnection TCP_PORT, (err) =>
                @tcp.end(JSON.stringify(
                    type: "desktop"
                    event: "bootend"
                ) + "\n")
