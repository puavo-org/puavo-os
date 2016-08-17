ViewMaster = require "../vendor/backbone.viewmaster"

LockScreenButtonView = require "../views/LockScreenButtonView.coffee"


describe "LockScreenButtonView", ->
    button = null
    afterEach ->
        button.remove()


    it "click bubbles lock-screen event", (done)->
        parent = new ViewMaster()
        parent.template = -> "<div></div>"
        button = new LockScreenButtonView
            hostType: "thinclient"
        parent.appendView("div", button)
        parent.once "lock-screen", done
        button.$el.trigger("click")
