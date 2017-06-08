_ = require "underscore"

class Navigation

    @key = key =
        ENTER: 13
        TAB: 9
        LEFT: 37
        UP: 38
        RIGHT: 39
        DOWN: 40

    activationKeys = [key.TAB, key.DOWN]
    navigationKeys = _.values(key)

    constructor: (views, cols) ->
        @views = views
        @cols = cols
        @selected = null
        @currentIndex = 0

    handleKeyEvent: (e) =>

        # Ignore event completely if it is not a navigation related key
        if e.which not in navigationKeys
            return

        # Capture key down event always if navigation is active or key is an
        # activation key
        if @isActive() or e.which in activationKeys
            e.preventDefault()

        # Call activation methods always on activation key
        if e.which is key.DOWN
            @down()
        if e.which is key.TAB
            @next()

        # Enter opens always the first app or the selected one
        if e.which is key.ENTER
            try
                @openItem()
            catch e
                console.log "ENTER pressed when nothing was selected"

        # Call other methods when navigation is active
        if @isActive()
            if e.which is key.LEFT
                @left()
            if e.which is key.RIGHT
                @right()
            if e.which is key.UP
                @up()

    isActive: -> !!@selected

    select: (view) ->
        @selected?.hideSelectHighlight()
        view.displaySelectHighlight()
        @selected = view
        view.scrollTo()

    next: ->
        if @isActive()
            @currentIndex += 1
            # Start from begining if on last item
            @currentIndex %= @views.length

        @select(@views[@currentIndex])

    down: ->
        if not @isActive()
            @select(@views[@currentIndex])
            return

        if @isOnLastRow()
            @deactivate()
            return

        @currentIndex += @cols
        @select(@views[@currentIndex])

    deactivate: ->
        @selected?.hideSelectHighlight()
        @selected = null
        @currentIndex = 0

    isOnFirstRow: -> @currentIndex+1 <= @cols
    isOnLastRow: -> @currentIndex > @views.length - @cols
    isOnFirstRowItem: -> @currentIndex % @cols is 0
    isOnLastRowItem: -> (@currentIndex+1) % @cols is 0
    isEmpty: -> !@views[@currentIndex]

    up: ->
        if @isOnFirstRow()
            @deactivate()
        else
            @currentIndex -= @cols
            @select(@views[@currentIndex])

    right: ->
        prev = @currentIndex

        if @isOnLastRowItem()
            @currentIndex -= @cols-1
        else
            @currentIndex += 1

        if @isEmpty()
            mod = prev % @cols
            @currentIndex = prev - mod

        @select(@views[@currentIndex])

    left: ->
        prev = @currentIndex

        if @isOnFirstRowItem()
            @currentIndex += @cols-1
        else
            @currentIndex -= 1

        if @isEmpty()
            @currentIndex = @views.length-1

        @select(@views[@currentIndex])

    openItem: ->
        if @isActive()
            @selected.open()
        else
            @views[0].open()

module.exports = Navigation
