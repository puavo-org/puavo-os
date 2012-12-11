
{expect} = require "chai"
menutools = require "../lib/menutools"

dir = __dirname + "/dotdesktop"
iconsDir = __dirname + "/icons"

describe "inject dot desktop data", ->
  describe "single item", ->

    menu = null
    beforeEach ->
      menu =
        type: "desktop"
        id: "thunderbird"
      menutools.injectDesktopData(menu, [dir], "fi_FI.UTF-8", [iconsDir], iconsDir + "/fallbackIcon")

    it "gets description", -> expect(menu.description).to.be.ok
    it "gets name", -> expect(menu.name).to.be.ok
    it "gets command", -> expect(menu.command).to.be.ok
    it "gets upstreamName", -> expect(menu.upstreamName).to.be.ok

  describe "menu.json can force attributes", ->

    menu = null
    beforeEach ->
      menu =
        type: "desktop"
        id: "thunderbird"
        name: "forced name"
      menutools.injectDesktopData(menu, [dir], "fi_FI.UTF-8", [iconsDir], iconsDir + "/fallbackIcon")

    it "should have forced name", ->
      expect(menu.name).to.eq "forced name"
