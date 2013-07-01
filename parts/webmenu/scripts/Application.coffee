Backbone = require "backbone"

Application =
  animationDuration: 2000
  reset: ->
    @bridge?.off()
    @bridge = new Backbone.Model

Application.reset()

module.exports = Application
