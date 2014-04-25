
var ffi = require("ffi");

var methods = {
  "dgettext": [ "string", ["string", "string"] ],
  "gettext": [ "string", ["string"] ],
  "bindtextdomain": [ "string", ["string", "string"] ],
  "textdomain": [ "string", ["string"] ]
};

// debian package has dropped libgettextlib.so. Try it first if were on
// Quantal. otherwise try to use libgettextpo.so.0 for Trusty.
// See changelog for 0.18.2.1-1) http://metadata.ftp-master.debian.org/changelogs/main/g/gettext/unstable_changelog
try {
  gettext = ffi.Library("libgettextlib", methods);
} catch (err) {
  gettext = ffi.Library("libgettextpo.so.0", methods);
}

var gettext;

module.exports = gettext;
