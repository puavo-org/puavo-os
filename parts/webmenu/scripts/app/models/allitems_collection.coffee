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
        if searchByWords item.get("name"), filterWords 
          return true
        if searchByWords item.get("description"), filterWords
          return true

        return false


searchByWords = (value, words) ->
  if not value
    return false
  if not words
    return false

  if typeof(words) is "string"
    words = [words]

  for word in words
    if value.indexOf(word) is -1
      return false

  return true
