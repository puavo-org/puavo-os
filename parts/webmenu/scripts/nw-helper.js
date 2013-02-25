
// Dummy adapter if not running in node-webkit
window.mochaNwAdapter = function() {};

(function() {
  if (!window.require) return;
  var util = window.require("util");
  var require = window.require;
  var process = window.process;
  var exitApp = !!window.process.env.exit;
  var gui = require('nw.gui');
  var Window = gui.Window.get();
  function log() {
    process.stderr.write(util.format.apply(util, arguments));
    process.stderr.write("\n");
  }

  function exit(code) {
    if (exitApp) {
      process.exit(code);
    }
  }

  // Display window and devtools if we are not going to exit after test running
  if (!exitApp) {
    Window.showDevTools();
    // Window is hidden from package.json. Display it!
    Window.show();
    // TODO: How to add frame back?
  }

  window.mochaNwAdapter = function(runner) {
    var fails = [];
    runner.on("fail", function(test, err) {
      fails.push({ test: test, err: err });
    });
    runner.on("end", function() {
      if (fails.length > 0) {
        log(fails);
        log("TEST FAILED!");
        exit(1);
      }
      else {
        log("TEST OK!");
        exit(0);
      }
    });
  };

  // Make room for RequireJS
  window.nodejs = {
     require: window.require,
     process: window.process,
  };
  window.require = window.process = undefined;
}());
