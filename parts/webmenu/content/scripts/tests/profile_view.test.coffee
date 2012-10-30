define [
  "cs!app/application"
  "cs!app/views/profile_view"
  "backbone"
], (
  Application
  ProfileView
  Backbone
) ->

  describe "ProfileView", ->
    view = null
    beforeEach ->
      view = new ProfileView
        model: new Backbone.Model(fullName: "John Doe")
      view.render()

    afterEach ->
      view.remove()

    it "should display user's fullname", ->
      expect(view.$el).to.contain("John Doe")

    describe "logout button", ->
      it "opens logout menu", ->
        view.$(".bb-logout").click()
        expect($("body")).to.have(".bb-lightbox")

    describe "my profile button", ->
      it "emits 'showMyProfileWindow'", (done) ->
        Application.on "showMyProfileWindow", -> done()
        view.$(".bb-profile-settings").click()

    describe "password button", ->
      it "emits 'showChangePasswordWindow'", (done) ->
        Application.on "showChangePasswordWindow", -> done()
        view.$(".bb-change-password").click()

    describe "settings button", ->
      it "emits 'openSettings'", (done) ->
        Application.on "openSettings", -> done()
        view.$(".bb-settings").click()



