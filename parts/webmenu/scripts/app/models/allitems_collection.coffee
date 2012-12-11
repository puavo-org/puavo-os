define [
  "backbone"
], (
  Backbone
) ->
  class AllItems extends Backbone.Collection


    favorites: (limit) ->
      items = @filter (m) -> m.get("type") isnt "menu" and m.get("clicks") > 0
      items.sort (a, b) -> b.get("clicks") - a.get("clicks")
      items = items.slice(0, limit) if limit
      return items

    searchFilter: (filterWords) ->
      console.log "Search Filter!"
      @filter (item) ->
        if item.get("type") is "menu"
          return false
        # FIXME
        if not item.get("name")
          return false
        if item.get("name").indexOf(filterWords) isnt -1
          return true

        return true
        #if item.get("name")  
      #@toArray()

