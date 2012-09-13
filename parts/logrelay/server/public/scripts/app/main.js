
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
    }
  },
  exclude: ["socket.io"],
  paths: {
    jquery: "vendor/jquery",
    underscore: "vendor/underscore",
    backbone: "vendor/backbone",
    "socket.io": "/socket.io/socket.io.js"
  }
});

require(["jquery", "underscore", "backbone", "socket.io"], function($, _, Backbone, io) {
  var socket;
  socket = io.connect();
  return socket.on("packet", function(packet) {
    return console.info("got packet", packet);
  });
});
