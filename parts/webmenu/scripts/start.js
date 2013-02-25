require([
  "jquery",
  "cs!app/application",
  "cs!app/main"],
  function($, Application) {

  // Connect "browser" and node.js
  window.nodejs.require("./lib/native")(
    window.gui, Application.bridge
  );

});

