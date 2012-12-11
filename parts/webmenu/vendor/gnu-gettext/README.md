# Node.JS bindings to GNU gettext

This a raw binding to GNU gettext with no extra sugar. Only extra is a shortcut
for the libc `setlocale` function.

## Installation

    npm install gnu-gettext

## Usage

```javascript
var gettext = require("gnu-gettext");

gettext.setLocale("LC_ALL", "fi_FI.UTF-8");
console.log(gettext.dgettext("gedit", "Text Editor")); // Tekstimuokkain
```

Note that these functions are syncronous by default. There is also asynchronous
version as this is the plain node-ffi object:

```javascrip:
gettext.dgettext.async(function(err, text){
  console.log(text);
});
```

There are some bindings still missing, but it's very easy to add them. Just
take a look at the gettext [manual][] and edit `gettext.js` accordingly and
send a pull request :)


## Alternatives

If you only need parser for `.po` and `.mo` files I recommed [node-gettext][] which
is a pure Javascript parser.

[node-gettext]: https://github.com/andris9/node-gettext
[manual]: http://www.gnu.org/software/gettext/manual/gettext.html

