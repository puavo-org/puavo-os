require('nw.gui').Window.get().resizeTo(screen.width, screen.height);
fs = require('fs');

var json = JSON.parse(fs.readFileSync('/etc/webkiosk.menu', 'utf8'));

if (json.hasOwnProperty("background")) {
  document.querySelector("body").setAttribute("background", json["background"]);
}

/* Add logo if it is defined in webkiosk.menu */

if (json.hasOwnProperty("logo")) {
  var logo_div = document.querySelector("#logo");

  logo = document.createElement("img");
  logo.appendChild(document.createTextNode(""));
  logo.setAttribute("class", "logo");
  logo.setAttribute("src", json["logo"]);

  logo_div.appendChild(logo);
}

/*

Add buttons for different languages

*/

var button_div = document.querySelector("#buttons");
var buttons=json["buttons"];

for (var key in buttons) {
  if (buttons.hasOwnProperty(key)) {
    button = document.createElement("button");
    button.appendChild(document.createTextNode(buttons[key]));
    button.setAttribute("value", key);
    button.setAttribute("class", "button");

    button_div.appendChild(button);
  }
}

var buttons = document.querySelectorAll("button");

[].forEach.call(buttons, function(el) {
    el.addEventListener("click", function(e) {
        process.stdout.write(e.target.value + "\n");
        process.exit(0);
    }, false);
});
