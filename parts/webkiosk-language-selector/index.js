require('nw.gui').Window.get().resizeTo(screen.width, screen.height);

var buttons = document.querySelectorAll("button");

[].forEach.call(buttons, function(el) {
    el.addEventListener("click", function(e) {
        process.stdout.write(e.target.value + "\n");
        process.exit(0);
    }, false);
});
