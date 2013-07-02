
Application = require "../Application.coffee"

renderFix = ->
    if Application.bridge.get("renderBug")
        console.warn "Rendering bug fix active"
        return ->
            body = $("body")
            body.detach()
            setTimeout ->
                body.appendTo("html")
            , 50
    return ->

module.exports = renderFix
