
ViewMaster = require "viewmaster"

maxLength = (s, max) ->
    return s if s.length <= max
    s.slice(0, -(s.length - max)) + "..."


replaceURLWithHTMLLinks = (text) ->
        exp = /\bhttps?:\/\/([-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
        return text.replace exp, (full, body) ->
                "<a href='#{ full }' title='#{ full }'>#{ maxLength(body, 30) }</a>"

class Carousel extends ViewMaster

    className: "bb-carousel"

    template: require "../templates/Carousel.hbs"

    constructor: ->
        super
        if not @collection
            throw new Error "Collection missing"

        @index = null

        @randomizeIndex()

        @listenTo @collection, "reset change", =>
            @randomizeIndex()
            @render()

        @on "reset", =>
            @randomizeIndex()
            @render()

    randomizeIndex: ->
        if @collection.size() is 0
            @index = null
        else
            @index = Math.round(Math.random() * (@collection.size()-1) )

    context: ->

        if @index is null
            return

        coll = @collection.at(@index)

        return {
            index: @index + 1
            size: @collection.size()
            item: coll.toJSON()
        }

    render: ->
        if @index is null
            @$el.empty()
        else
            super

    afterTemplate: ->
        msg = @$(".message p").get(0)
        msg.innerHTML = replaceURLWithHTMLLinks(msg.innerHTML)

    events: {
        "click .next": ->
            @index = (@index + 1) % @collection.size()
            @render()
        "click .prev": ->
            if @index is 0
                @index = @collection.size() - 1
            else
                @index = (@index - 1) % @collection.size()
            @render()
        "click a": (e) ->
            e.preventDefault()
            @bubble("open-app", {
                type: "web"
                url: e.target.href
            })
    }


module.exports = Carousel

