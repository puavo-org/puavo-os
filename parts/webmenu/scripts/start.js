require([
  "jquery",
  "cs!app/application",
  "cs!app/main"],
  function($, Application, boot) {
  var APP_CONFIG = nodeConnect(window.nativeWindow, Application.bridge);
  console.log("Booting app");
  boot(APP_CONFIG.user, APP_CONFIG.config, APP_CONFIG.menu);

});

