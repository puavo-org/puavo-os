define ->
  if window.nodejs.process.env.RENDER_BUG
    console.warn "Rendering bug fix active"
    return ->
      body = $("body")
      body.detach()
      setTimeout ->
        body.appendTo("html")
      , 50
  else
    return ->
