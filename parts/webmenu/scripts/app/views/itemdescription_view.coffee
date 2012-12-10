define [
  "backbone.viewmaster"

  "hbs!app/templates/itemdescription"
], (
  ViewMaster

  template
) ->
  class ItemDescriptionView extends ViewMaster
    className: "bb-item-description"
    template: template
