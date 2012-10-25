/*
 * _.debounce with debounced.cancel()
 * http://underscorejs.org/#debounce
 *
 * */
define(["underscore"], function(_) {
  return function(fn, time) {
    var canceled = false;

    // Call the orignal function if it is not canceled
    var callWrap = function() {
      if (!canceled) return fn.apply(null, arguments);
    };

    var debounced = _.debounce(callWrap, time);

    // Disable cancellation on next call on the debounced function
    var debouncedWrap = function() {
      canceled = false;
      return debounced.apply(null, arguments);
    };

    debouncedWrap.cancel = function() {
      canceled = true;
    };

    return debouncedWrap;
  };
});
