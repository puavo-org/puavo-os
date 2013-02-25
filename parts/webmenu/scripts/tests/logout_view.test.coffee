define [
  "cs!app/application"
  "cs!app/views/logout_view"
  "cs!app/views/lightbox_view"
], (
  Application
  LogoutView
  Lightbox
) ->

  describe "LogoutView", ->
    view = null
    beforeEach ->
      Application.reset()
      view = new LogoutView
        hostType: "fatclient"
      view.render()
    afterEach ->
      view.remove()

    describe "logout button", ->
      it "emits logout event", (done) ->
        Backbone.once "logout", -> done()
        view.$(".bb-logout").click()

    describe "shutdown button", ->
      it "emits shutdown event", (done) ->
        Backbone.once "shutdown", -> done()
        view.$(".bb-shutdown").click()

    describe "reboot button", ->
      it "emits reboot event", (done) ->
        Backbone.once "reboot", -> done()
        view.$(".bb-reboot").click()

