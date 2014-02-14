
ViewMaster = require "viewmaster"


replaceURLWithHTMLLinks = (text) ->
    exp = /\bhttps?:\/\/([-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
    return text.replace exp, (full, body) ->
        "<a href='#{ full }'>#{ body }</a>"

class Carousel extends ViewMaster

    className: "bb-carousel"

    template: require "../templates/Carousel.hbs"

    constructor: ->
      super
      @index = 0

    context: ->
      console.log "Using index #{ @index }"

      return {
        index: @index + 1
        size: @collection.size()
        item:  @collection.at(@index).toJSON()
      }

    render: ->
      if not @collection or @collection?.size() is 0
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

