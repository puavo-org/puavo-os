window.expect = chai.expect
window.assert = chai.assert
mocha.setup("bdd")

Backbone = require "backbone"
Backbone.$ = window.jQuery

Application = require "../Application.coffee"
Application.animationDuration = 10

require "./SidebarView.test.coffee"
require "./ProfileView.test.coffee"
require "./LogoutButtonView.test.coffee"
require "./LockScreenButtonView.test.coffee"
require "./AllItems.test.coffee"
require "./MenuItemView.test.coffee"
require "./MenuListView.test.coffee"
require "./MenuLayout.test.coffee"
require "./MenuModel.test.coffee"
require "./Navigation.test.coffee"
require "./Search.test.coffee"
require "./Feedback.test.coffee"

runner = mocha.globals(["jQuery*"]).run()

fails = []

runner.on "fail", (test, error) ->
    fails.push { test, error }
    for fail in fails
        console.error "FAIL: #{ test.title }: #{ error.message }"
        console.error error.stack

runner.on "end", ->
    console.log "~~NW TESTS OK~~" if fails.length is 0
    window.EXIT?(
        if fails.length
            1
        else
            0
    )
