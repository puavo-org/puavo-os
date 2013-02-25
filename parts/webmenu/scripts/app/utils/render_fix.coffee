define [
  "cs!app/application"
], (
  Application
) ->
  if Application.bridge.get("renderBug")
    console.warn "Rendering bug fix active"
    return ->
      body = $("body")
      body.detach()
      setTimeout ->
        body.appendTo("html")
      , 50
  else
    return ->
