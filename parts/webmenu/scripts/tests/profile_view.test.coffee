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
        config: new Backbone.Model
          profileCMD:
            type: "webWindow"
            url: "http://profile.example.com"
          passwordCMD:
            type: "webWindow"
            url: "http://password.example.com"
          settingsCMD:
            type: "custom"
            command: "gnome-control-center"

      view.render()

    afterEach ->
      view.remove()
      Application.reset()

    it "should display user's fullname", ->
      expect(view.$el).to.contain("John Doe")

    it "should have profile settings button", ->
      expect(view.$el).to.have(".bb-profile-settings")

    it "should have change password button", ->
      expect(view.$el).to.have(".bb-change-password")

    describe "logout button", ->
      it "opens logout menu", ->
        view.$(".bb-logout").click()
        expect($("body")).to.have(".bb-lightbox")

    describe "my profile button", ->
      it "emits 'open' event on bridge with profile cmd", (done) ->
        Application.bridge.on "open", (cmd) ->
          expect(cmd).to.deep.eq
            type: "webWindow"
            url: "http://profile.example.com"
          done()
        view.$(".bb-profile-settings").click()

    describe "password button", ->
      it "emits 'open' event on bridge with password cmd", (done) ->
        Application.bridge.on "open", (cmd) ->
          expect(cmd).to.deep.eq
            type: "webWindow"
            url: "http://password.example.com"
          done()
        view.$(".bb-change-password").click()

    describe "emits 'open' event on bridge with settings cmd", ->
      it "emits ", (done) ->
        Application.bridge.on "open", (cmd) ->
          expect(cmd).to.deep.eq
            type: "custom"
            command: "gnome-control-center"
          done()
        view.$(".bb-settings").click()

    describe "with missing changePasswordUrl&profileUrl", ->

      beforeEach ->
        view.config.set
          passwordCMD: null
          profileCMD: null
        view.render()

      it "should not have profile settings button", ->
        expect(view.$el).to.not.have(".bb-profile-settings")

      it "should not have change password button", ->
        expect(view.$el).to.not.have(".bb-change-password")


