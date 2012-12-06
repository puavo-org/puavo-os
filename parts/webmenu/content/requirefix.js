/**
 * Make sure that AppJS cannot override RequireJS require function.
 *
 * At some time during start up AppJS tries to put node.js require function to
 * window.require. From now on if window.require is an function the RequireJS
 * require function is always returned.
 *
 **/
(function() {
  var currentValue;

  Object.defineProperty(window, "require", {
    set: function(value) {
      currentValue = value;
    },

    get: function() {
      // If window.require is set to function always return RequireJS require.
      if (typeof currentValue === "function") {
        return window.requirejs;
      }
      // Other values work as usual. (RequireJS config object).
      else {
        return currentValue;
      }
    }

  });
}());
