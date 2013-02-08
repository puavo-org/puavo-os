define [
  "backbone.viewmaster"

  "cs!app/views/logout_button_view"
], (
  ViewMaster

  LogoutButtonView
) ->

  describe "LogoutButtonView", ->
    button = null
    afterEach ->
      button.remove()


    it "click bubbles open-logout-view event", (done)->
      parent = new ViewMaster()
      parent.template = -> "<div></div>"
      button = new LogoutButtonView
        hostType: "thinclient"
      parent.appendView("div", button)
      parent.once "open-logout-view", done
      button.$el.trigger("click")



