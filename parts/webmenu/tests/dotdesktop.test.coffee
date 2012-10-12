
{expect} = require "chai"
dotdesktop = require "../lib/dotdesktop"

dir = __dirname + "/dotdesktop"


describe "locale parser", ->

  it "can parse full locale", ->
    expect(dotdesktop.parseLocale("fi_FI.UTF-8")).to.deep.eq(
      locale: "fi_FI"
      encoding: "UTF-8"
      lang: "fi"
      original: "fi_FI.UTF-8"
    )

  it "can parse locale without encoding", ->
    expect(dotdesktop.parseLocale("fi_FI")).to.deep.eq(
      locale: "fi_FI"
      lang: "fi"
      original: "fi_FI"
    )


describe "desktop file with embedded translations", ->

  describe "with existing translation", ->

    thunderbird = dotdesktop.parseFileSync dir + "/thunderbird.desktop", "fi_FI.UTF-8"

    it "has finnish translation", ->
      expect(thunderbird.name).to.eq "Sähköpostiohjelma"
      expect(thunderbird.description).to.eq "Lue ja kirjoita sähköposteja"
      expect(thunderbird.lang).to.eq "fi"
      expect(thunderbird.command).to.eq "thunderbird"

  describe "with unknown translation", ->

    thunderbird = dotdesktop.parseFileSync dir + "/thunderbird.desktop", "xx_XX.UTF-8"

    it "gets english", ->
      expect(thunderbird.name).to.eq "Mail Client"
      expect(thunderbird.description).to.eq "Send and receive mail with Thunderbird"



describe "desktop file with embedded translations", ->

  gedit = dotdesktop.parseFileSync dir + "/gedit.desktop", "fi_FI.UTF-8"

  it "has finnish translation", ->
    expect(gedit.name).to.eq "Tekstimuokkain"


describe "desktop file with missing generic name", ->

    thunderbird = dotdesktop.parseFileSync dir + "/thunderbird_no_generic_name.desktop", "fi_FI.UTF-8"

    it "falls back to normal name", ->

      expect(thunderbird.name).to.eq "Thunderbird-sähköposti"


describe "desktop file without any translations", ->

  thunderbird = dotdesktop.parseFileSync dir + "/thunderbird_no_translations.desktop", "fi_FI.UTF-8"

  it "return the original", ->

      expect(thunderbird.name).to.eq "Mail Client"
