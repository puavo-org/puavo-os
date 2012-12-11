
{expect} = require "chai"
menutools = require "../lib/menutools"

dir = __dirname + "/dotdesktop"
iconsDir = __dirname + "/icons"
fallbackIconPath = iconsDir + "/fallbackIcon.png"

describe "inject dot desktop data", ->
  describe "single item", ->

    menu = null
    beforeEach ->
      menu =
        type: "desktop"
        id: "thunderbird"
      menutools.injectDesktopData(menu, [dir], "fi_FI.UTF-8", [iconsDir], fallbackIconPath)

    it "gets description", -> expect(menu.description).to.be.ok
    it "gets name", -> expect(menu.name).to.be.ok
    it "gets command", -> expect(menu.command).to.be.ok
    it "gets upstreamName", -> expect(menu.upstreamName).to.be.ok
    it "gets icon", -> expect(menu.osIconPath).to.eq iconsDir + "/thunderbird.png"


  describe "menu.json can force attributes", ->

    menu = null
    beforeEach ->
      menu =
        type: "desktop"
        id: "thunderbird"
        name: "forced name"
      menutools.injectDesktopData(menu, [dir], "fi_FI.UTF-8", [iconsDir], fallbackIconPath)

    it "should have forced name", ->
      expect(menu.name).to.eq "forced name"

  describe "when icon not found use default icon for", ->

    menus = [
      {
        type: "desktop"
        id: "gedit"
      }, {
        type: "custom"
        name: "Test Application"
        command: "test-command"
        description: "test description"
        osIcon: "testIcon"
      }, {
        type: "web"
        name: "Walma"
        url: "http://walmademo.opinsys.fi"
        description: "Yhteistoiminnallinen piirtotaulu"
        osIcon: "emblem-pictures"
      }
    ]
      

    menus.forEach (menu) ->
      menutools.injectDesktopData(menu, [dir], "fi_FI.UTF-8", [iconsDir], fallbackIconPath)

      it "#{menu.name} (#{menu.type})", ->
        expect(menu.osIconPath).to.eq fallbackIconPath
