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
      @_previousCount = 0
      @model.clients.on "add remove change", =>
        @animate()


    animate: ->

      # Do not interrupt animations since it looks ugly. Just render the
      # content in that case.
      if @_animationTimer
        @render()
        return

      if @model.clients.activeClientCount() is @_previousCount
        return

      if @model.clients.activeClientCount() > @_previousCount
        @_animateConnect()
      else
        @_animateDisconnect()

      @_animationTimer = setTimeout =>
        @_animationTimer = null
        @_clearAnimation()
        # Render content after animation so it will be clear to user what changed.
        @render()
      , 1300 # is the default animation duration in animate.css

      @_previousCount = @model.clients.activeClientCount()

    _animateConnect: -> @$el.addClass "animated tada"
    _animateDisconnect: -> @$el.addClass "animated wobble"

    _clearAnimation: ->
      clearTimeout @_animationTimer if @_animationTimer
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
      super
      @setSprite()




