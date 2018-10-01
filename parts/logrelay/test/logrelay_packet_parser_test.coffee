
assert = require "assert"

logRelayPacketParse = require "../lib/logrelay_packet_parse"

describe "Logrelay packet parser", ->

  it "can parse single line", ->
    data = "foo:bar"
    ob = logRelayPacketParse(data)
    assert.deepEqual ob, { foo: "bar" }

  it "can parse multiple lines", ->
    data = "foo:bar\nbaz:foo"
    ob = logRelayPacketParse(data)
    assert.deepEqual ob, { foo: "bar", baz: "foo" }

  it "can parse array", ->
    data = "foo:[bar,baz]"
    ob = logRelayPacketParse(data)
    assert.deepEqual ob, { foo: ["bar", "baz" ] }

  it "ignores empty lines", ->
    data = "foo:bar\n\nbaz:foo"
    ob = logRelayPacketParse(data)
    assert.deepEqual ob, { foo: "bar", baz: "foo" }

  it "can parse values with colons", ->
    data = "mac:foo:bar:baz"
    ob = logRelayPacketParse(data)
    assert.deepEqual ob, { mac: "foo:bar:baz" }

  it "colons work in arrays too", ->
    data = "macs:[foo:bar:baz,foo:bar:baz]"
    ob = logRelayPacketParse(data)
    assert.deepEqual ob, { macs: ["foo:bar:baz","foo:bar:baz"]  }

