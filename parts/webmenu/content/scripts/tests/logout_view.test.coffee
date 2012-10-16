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
      view = new LogoutView
      view.render()

    describe "logout button", ->
      it "emits logout event", (done) ->
        Application.on "logout", -> done()
        view.$(".bb-logout").click()

    describe "shutdown button", ->
      it "emits shutdown event", (done) ->
        Application.on "shutdown", -> done()
        view.$(".bb-shutdown").click()

    describe "reboot button", ->
      it "emits reboot event", (done) ->
        Application.on "reboot", -> done()
        view.$(".bb-reboot").click()
