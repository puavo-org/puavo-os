require([
  "jquery",
  "cs!app/application",
  "cs!app/main"],
  function($, Application) {
  nodeConnect(window.gui, Application.bridge);
});

