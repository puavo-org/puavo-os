define [
  "cs!app/view"
  "hbs!app/templates/sidebar"
], (
  View
  template
) ->

  class SidebarView extends View

    className: "sidebar-container"

    template: template
