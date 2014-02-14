Backbone = require "backbone"
ViewMaster = require "viewmaster"

LauncherModel = require "../models/LauncherModel.coffee"
MenuItemView = require "./MenuItemView.coffee"
LogoutButtonView = require "./LogoutButtonView.coffee"
Carousel = require "./Carousel.coffee"

class ProfileView extends ViewMaster

    className: "bb-profile"

    template: require "../templates/ProfileView.hbs"

    constructor: (opts) ->
        super
        @config = opts.config

        if settingsCMD = @config.get("settingsCMD")
            @settings = new MenuItemView
                model: new LauncherModel settingsCMD
            @appendView ".settings-container", @settings

        if passwordCMD = @config.get("passwordCMD")
            @password = new MenuItemView
                model: new LauncherModel passwordCMD
            @appendView ".settings-container", @password

        if profileCMD = @config.get("profileCMD")
            @profile = new MenuItemView
                model: new LauncherModel profileCMD
            @appendView ".settings-container",  @profile

        if supportCMD = @config.get("supportCMD")
            @support = new MenuItemView
                model: new LauncherModel supportCMD
            @appendView ".settings-container",  @support

        @appendView ".settings-container", LogoutButtonView
        @appendView ".footer-container",  new Carousel
            collection: new Backbone.Collection([
                {
                    type: "opinsys"
                    name: "Opinsys"
                    message: "Tule tutustumaan ohjelmoitavaan nalleen (7e29) http://opinsys.fi"
                }
                {
                    type: "opinsys"
                    name: "Opinsys"
                    message: "Foo bar"
                }
                {
                    type: "opinsys"
                    name: "Opinsys"
                    message: "sadfk sadlfkjsda lsfda jfdlkj fdlksdfaj dslafkj flk jfsdlj sadfldfsaj dfskl asd sdf sdakfj sdfj sda jksadkj sad asdsadjk sadflk sadflas salkj slk jsal ks ljkslkj l sdfksdfl ksdfal ksadl sda fsdalkjfsda lkdfsjfdsj faklfjlsad jfsdl kjflsaj fldsj flsjadlfj sdfkjds alkfjsdlkfjsadlkjfsla lsda jfl jsdalfj slkajflj sdalkf jsadljf lksad jflk sjdafjsadlkjflks dajflksj aflkj welkj fwelkj flkajflkasdjlkfj salkfjlsakd  sdfaloppu "
                }
            ])



    context: -> {
        user: @model.toJSON()
        config: @config.toJSON()
    }

module.exports = ProfileView
