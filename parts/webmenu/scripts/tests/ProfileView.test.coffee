Backbone = require "backbone"
Application = require "../Application.coffee"
ProfileView = require "../views/ProfileView.coffee"

class MockFeeds extends Backbone.Collection
    fetch: ->


config =
    profileCMD:
        id: "profile"
        name: "Profile"
        type: "webWindow"
        url: "http://profile.example.com"

describe "ProfileView", ->

    describe "with basic contents", ->
        view = null
        beforeEach ->
            view = new ProfileView
                user: new Backbone.Model(fullName: "John Doe")
                config: new Backbone.Model config

            view.render()

        afterEach ->
            view.remove()

        it "should display user's fullname", ->
            expect(view.$el).to.contain("John Doe")

        it "should have profile settings button", ->
            expect(view.$el).to.have(".profile")

        describe "my profile link", ->
            it "emits open-app for profile edit on profile link click", (done) ->
                view.once "open-app", (model) ->
                    expect(model.url).to.eq "http://profile.example.com"
                    expect(model.type).to.eq "webWindow"
                    done()
                view.$el.find('.profile').click()


    describe "with missing profileUrl", ->

        view = null
        after -> view.remove()
        before ->
            view = new ProfileView
                user: new Backbone.Model(fullName: "John Doe")
                config: new Backbone.Model
                    profileCMD: null
            view.render()

        it "should not have profile settings button", ->
            expect(view.profile).to.be.not.ok


