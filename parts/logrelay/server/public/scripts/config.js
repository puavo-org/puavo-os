
require.config({
  baseUrl: "/scripts",
  shim: {
    underscore: {
      exports: "_"
    },
    backbone: {
      deps: ["underscore", "jquery"],
      exports: "Backbone"
    },
    "socket.io": {
      exports: "io"
    },
    "handlebars": {
      exports: "Handlebars"
    }
  },
  paths: {
    jquery: "vendor/jquery",
    handlebars: "vendor/handlebars",
    underscore: "vendor/underscore",
    backbone: "vendor/backbone",
    moment: "vendor/moment",
    "socket.io": "vendor/socket.io",
    "coffee-script": "vendor/coffee-script"
  }
});

require(["cs!app/main"], function() {
  console.log("main app loaded");
});
