Backbone = require "backbone"
_ = require "underscore"

class AllItems extends Backbone.Collection

    favorites: ->
        items = @filter (m) -> m.get("type") isnt "menu" and m.get("clicks") > 0
        items.sort (a, b) -> b.get("clicks") - a.get("clicks")
        items = items[0..3]    # there's no room for more than 4 favorites
        return items

    searchFilter: (filterWords) ->
        @filter (item) ->
            if item.get("type") is "menu"
                return false
            else
                filterWords = [filterWords] if not _.isArray(filterWords)
                return recurMatch(item.toJSON(), filterWords)

###*
# Case insensitive string match.
#
# Return true if needle is found from source
#
# @param {String} source
# @param {String} needle
# @return {Boolean}
###
hasString = (source, needle) ->
    source.toString().toLowerCase().indexOf(needle.toLowerCase()) isnt -1

###*
# Recursively detect whether one of the `needles` appears in the given JSON
# object.
#
# @param {Object} ob
# @param {Array} needles Array of needles to search from `ob`
# @return {Boolean}
###
recurMatch = (ob, needles) ->
    return false if not ob

    # Threat strings and numbers as the leafs
    if typeof(ob) in  ["string", "number"]
        for n in needles when hasString(ob, n)
            return true
        return false

    # Convert objects (and arrays) to arrays of values recur into them
    return  _.values(ob).some (v) -> recurMatch(v, needles)

module.exports = AllItems
