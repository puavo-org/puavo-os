define [
  "cs!app/utils/dom2bb"
], (
  Dom2Bb
) ->

  describe "dom to backbone events adapter", ->

    it "emits events to itself with trigger", (done) ->
      div = document.createElement("div")
      bb = new Dom2Bb(div)
      bb.on "test", -> done()
      bb.trigger "test"

    it "emits events from dom element", (done) ->
      div = document.createElement("div")
      bb = new Dom2Bb(div)
      bb.on "test", -> done()
      div.dispatchEvent(new window.Event("test"))

    it "emits events to dom element", (done) ->
      div = document.createElement("div")
      bb = new Dom2Bb(div)
      div.addEventListener "test", -> done()
      bb.trigger "test"
