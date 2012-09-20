define [
  "cs!app/view"
  "cs!app/url"
  "jquery"
  "moment"
  "underscore"
], (
  View
  url
  $
  moment
  _) ->
  class SchoolSelect extends View

    className: "bb-school-select"
    templateQuery: "#school-select"

    constructor: (opts) ->
      super
      @model.on "change", => @render()

    events:
      "change select": (e) ->
        schoolId = e.target.value
        window.location = url.newPath url.currentOrg, schoolId

    render: ->
      # Do not render if schools are not loaded yet
      if not @model.get "otherSchools"
        return ""
      super


    viewJSON: ->
      schools = []
      currentSchool = null
      for id, name of @model.get("otherSchools")
        if id is url.currentSchoolId
          currentSchool =
            id: id
            name: name
        else
          schools.push
            id: id
            name: name

      return {
        currentSchool: currentSchool
        org: url.currentOrg
        schools: schools
      }


