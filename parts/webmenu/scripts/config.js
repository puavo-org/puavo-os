require.config({
  hbs: {
    disableI18n: true
  },
  shim: {
    backbone: {
      deps: ["underscore", "jquery"],
      exports: "Backbone"
    },
    "backbone.viewmaster": {
      deps: ["backbone"],
      exports: "Backbone.ViewMaster"
    },
    "socket.io": {
      exports: "io"
    },
    "uri": {
      exports: "URI"
    }
  },
  paths: {
    jquery: "vendor/jquery",
    json2: "vendor/json2",
    i18nprecompile: "vendor/i18nprecompile",
    underscore: "vendor/underscore",
    "underscore.string": "vendor/underscore.string",
    backbone: "vendor/backbone",
    "backbone.viewmaster": "vendor/backbone.viewmaster/lib/backbone.viewmaster",
    moment: "vendor/moment",
    uri: "vendor/URI",
    "socket.io": "vendor/socket.io",
    "coffee-script": "vendor/coffee-script",
    "spin": "vendor/spin"
  }
});
