define [
  "cs!app/view"
  "moment"
  "underscore"
], (View, moment, _) ->

  padZero = (num, size) ->
    s = num + ""
    while s.length < size
      s = "0" + s
    s

  class WlanStats extends View

    className: "bb-wlan-stats"
    templateQuery: "#wlan-stats"

    events:
      "click": (e) ->
        @model.trigger "select", @model
        @animate()

    constructor: (opts) ->
      super
      @previousCount = 0
      @model.clients.on "add remove change", =>
        @render()

      @model.collection.on "select", (model) =>
        @disableAnimation = true
        @selected = model.id is @model.id
        @render()

    animate: ->


      if @disableAnimation
        @disableAnimation = false
        return

      if @model.clients.activeClientCount() is @previousCount
        return

      if @model.clients.activeClientCount() > @previousCount
        @animateClientConnected()
      else
        @animateClientLeft()

      @animTimer = setTimeout =>
        @clearAnimation()
      , 1300

      @previousCount = @model.clients.activeClientCount()

    animateClientConnected: -> @$el.addClass "animated tada"
    animateClientLeft: -> @$el.addClass "animated wobble"

    clearAnimation: ->
      clearTimeout @animTimer if @animTimer
      @$el.removeClass "animated wobble tada"

    viewJSON: ->
      count: @model.activeClientCount()
      name: @model.id

    # Visual presentation of a wlan host compared to others in scale of 0-10
    wlanBarCount: ->
      count = @model.clients.activeClientCount()

      # No bars if no clients
      if count is 0
        return 0

      # One bar if there is one client
      if count is 1
        return 1

      largestHost = _.max @model.collection.map (m) ->
        m.clients.activeClientCount()

      # Otherwise just scale bars to largest host
      return Math.round count / largestHost * 12, 1

    setSprite: ->
      wlanSpriteClass = "wlanwlan#{ padZero  @wlanBarCount(), 2 }"

      return if @$el.hasClass wlanSpriteClass
      @$el.addClass wlanSpriteClass
      @$el.removeClass @previousSpriteClass if @previousSpriteClass
      @previousSpriteClass = wlanSpriteClass

    render: ->
      @clearAnimation()
      super

      @setSprite()

      if @selected
        @$el.addClass "selected"
      else
        @$el.removeClass "selected"

      @animate()




