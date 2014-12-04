var fs = require('fs');
var gui = require('nw.gui');

url = gui.App.argv[0];
if (!url) {
  process.stderr.write("Give url as an argument!\n");
  process.exit(1);
}

function read_a_line(filepath) {
  return fs.readFileSync(filepath)
           .toString()
           .replace(/\n$/, '');
}

var this_ltspimage_name    = read_a_line('/etc/ltsp/this_ltspimage_name');
var this_ltspimage_release = read_a_line('/etc/ltsp/this_ltspimage_release');

gui.App.clearCache();

var title_element = document.querySelector('title');
title_element.textContent = this_ltspimage_release
                              + " - "
                              + this_ltspimage_name;

var loaded = false;
var changelog = document.querySelector('#changelog_iframe');

changelog.src = url;

function changelog_loaded() {
  try {
    var doc = changelog.contentDocument.documentElement;
    if (doc.querySelector('head').querySelector('title')) {
      process.stdout.write("Changelog load OK.\n");
      loaded = true;

      var load_msg = document.querySelector('#loading_msg');
      load_msg.parentNode.removeChild(load_msg);
    }
  } catch (ex) {}
}

changelog.onload = changelog_loaded;

function handle_connection_timeout() {
  if (loaded) { return }

  var div = document.querySelector('#changelog_div');
  div.textContent = 'Could not load changelog... (network error?)';
  setTimeout(function() { process.exit(1); }, 10000);
}

setTimeout(handle_connection_timeout, 20000);
