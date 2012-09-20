define [
  "jquery"
  "underscore"
  "backbone"
  "handlebars"
  "cs!app/url"
], (
  $
  _
  Backbone
  Handlebars
  url
) -> $ ->

  $(".org-title").text url.currentOrg

  $.get "/schools/#{ url.currentOrg }", (schools, status, res) ->
    if status isnt "success"
      console.error res
      throw new Error "failed to fetch school list"

    template = Handlebars.compile $("#school-list").html()

    schools = for id, name of schools
      {
        id: id
        name: name
        url: url.newPath url.currentOrg, id
      }

    $(".content").html template schools: schools

