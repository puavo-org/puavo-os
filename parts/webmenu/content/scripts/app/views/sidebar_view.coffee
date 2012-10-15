define [
  "cs!app/view"
  "hbs!app/templates/sidebar"
  "cs!app/application"
], (
  View
  template
  Application
) ->

  class SidebarView extends View

    className: "sidebar-container"

    template: template

    events:
      "click .bb-profile": (e) ->
        Application.trigger "showMyProfileWindow"

