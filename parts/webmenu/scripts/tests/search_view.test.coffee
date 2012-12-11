define [
  "cs!app/views/search_view"
],
(
  Search
) ->

  describe "Search view", ->

    it "emit 'changeFilter' event on keyup", (done) ->
      view = new Search
      view.on "changeFilter", (filter) ->
        expect(filter).to.eq "test"
        done()

      view.render()
      view.$input.val("test")
      view.$input.trigger("keyup")


