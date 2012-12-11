
var ffi = require("ffi");

var gettext = ffi.Library("libgettextlib", {
  "dgettext": [ "string", ["string", "string"] ],
  "gettext": [ "string", ["string"] ],
  "bindtextdomain": [ "string", ["string", "string"] ],
  "textdomain": [ "string", ["string"] ]
});

module.exports = gettext;
