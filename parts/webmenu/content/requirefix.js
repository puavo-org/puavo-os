/**
 * Make sure that Appjs cannot override RequireJS require global.
 *
 * @module requirefix
 **/
(function() {
  var requireJSrequire;

  Object.defineProperty(window, "require", {
    set: function(val) {

      if (typeof val === "function" && val.length !== 4) {
        console.log("AppJS is trying to force node.js require to us. Ignoring it.", val);
        // Use require from RequireJS
        requireJSrequire =  window.requirejs;
      }
      else {
        requireJSrequire = val;
      }
    },

    get: function() {
      return requireJSrequire;
    }

  });
}());
