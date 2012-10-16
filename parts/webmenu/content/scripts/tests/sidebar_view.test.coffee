define [
  "cs!app/application"
  "cs!app/views/sidebar_view"
], (
  Application
  SideBarView
) ->

  describe "SideBarView", ->
    view = null
    beforeEach ->
      view = new SideBarView
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
        view.$(".bb-profile").click()


