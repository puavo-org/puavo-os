define [
  "backbone"
  "underscore"
], (
  Backbone
  _
) ->
  class AllItems extends Backbone.Collection


    favorites: (limit) ->
      items = @filter (m) -> m.get("type") isnt "menu" and m.get("clicks") > 0
      items.sort (a, b) -> b.get("clicks") - a.get("clicks")
      items = items.slice(0, limit) if limit
      return items

    searchFilter: (filterWords) ->
      @filter (item) ->
        if item.get("type") is "menu"
          return false
        else
          filterWords = [filterWords] if not _.isArray(filterWords)
          return recurMatch(item.toJSON(), filterWords)

hasString = (source, needle) ->
  source.toString().toLowerCase().indexOf(needle.toLowerCase()) isnt -1

recurMatch = (ob, needles) ->
  return false if not ob

  if typeof(ob) in  ["string", "number"]
    for n in needles when hasString(ob, n)
      return true
    return false

  return  _.values(ob).some (v) -> recurMatch(v, needles)
