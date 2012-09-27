var app = module.exports = require('appjs');
var http = require("http");

app.serveFilesFrom(__dirname + '/content');

var window = app.createWindow({
  width  : 1000,
  height : 480,
  top : 200,
  showChrome: false,
  opacity : 0.5,
  alpha : true,
  icons  : __dirname + '/content/icons'
});


window.on('create', function(){
  console.log("Window Created");
  window.frame.show();
  window.frame.center();
});



function showAgain(){
  console.log("show again");
  window.frame.hide();
  window.frame.show();
  window.frame.topmost = true;
}

function hideApp(){
  window.frame.hide();
}

httpServer = http.createServer(function (req, res) {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Showing window');
    showAgain();
}).listen(1337, '127.0.0.1');

window.on('ready', function(){
  console.log("Window Ready");
  window.require = require;
  window.process = process;
  window.module = module;

  window.addEventListener('log', function(e, a){
    console.log("LOG", e.msg);
  });

  window.addEventListener('hide', hideApp);
  window.addEventListener('focusout', hideApp);

  function F12(e){ return e.keyIdentifier === 'F12'; }
  function Command_Option_J(e){ return e.keyCode === 74 && e.metaKey && e.altKey; }

  window.addEventListener('keydown', function(e){
    if (F12(e) || Command_Option_J(e)) {
      window.frame.openDevTools();
    }
  });
});

window.on('close', function(){
  console.log("Window Closed");
  process.exit(0);
});
