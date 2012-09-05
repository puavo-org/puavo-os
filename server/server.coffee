
express = require "express"
app = express()
app.use express.bodyParser()

app.get "/", (req, res) ->
  res.send "hello"

app.post "/log", (req, res) ->
  console.info req.body
  res.send "thanks"

app.listen 8080, ->
  console.info "Server listening on 8080"

