Search = require "../views/Search.coffee"

describe "Search view", ->

  it "emit 'search' event on keyup", (done) ->
    view = new Search
    view.on "search", (filter) ->
      expect(filter).to.eq "test"
      done()

    view.render()
    view.$input.val("test")
    view.$input.trigger("keyup")

