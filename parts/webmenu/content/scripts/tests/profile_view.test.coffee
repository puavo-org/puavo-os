define [
  "cs!app/application"
  "cs!app/views/profile_view"
], (
  Application
  ProfileView
) ->

  describe "ProfileView", ->
    view = null
    beforeEach ->
      view = new ProfileView
      view.render()
    afterEach ->
      view.remove()

    describe "logout button", ->
      it "opens logout menu", ->
        view.$(".bb-logout").click()
        expect($("body")).to.have(".bb-lightbox");

    describe "my profile button", ->
      it "emits 'showMyProfileWindow'", (done) ->
        Application.on "showMyProfileWindow", -> done()
        view.$(".bb-profile-settings").click()

    describe "settings button", ->
      it "emits 'openSettings'", (done) ->
        Application.on "openSettings", -> done()
        view.$(".bb-settings").click()

