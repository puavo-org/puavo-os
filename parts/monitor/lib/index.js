
var fs = require("fs");
var os = require("os");
var net = require("net");
var config = require("/etc/puavo-monitor.json");
var _ = require("underscore");
var JSONStream = require("json-stream");

var devices = require("./devices");
var getXUser = require("./user");
var lock = require("./lock")
var hostType = require("./hosttype");
var hostname;
var PING_TIMEOUT = 1000 * 10;

try {
  // On new systems puavo-register writes registered hostname to
  // /etc/puavo/hostname
  hostname = fs.readFileSync("/etc/puavo/hostname").toString().trim();
}
catch (err) {
  if (err.code !== "ENOENT") throw err;

  // On older systems (lucid) we can safely fallback to hostname syscall
  hostname = os.hostname();
}


/**
 * @return random int from 10000 to 60000
 **/
function rand10to60() {
  return (10 + parseInt(Math.random() * 50, 10)) * 1000;
}

/**
 * Retry connection after some timeout if logrelay disconnects us. Use random
 * timeout to somewhat balance reconnections.
 **/
function retry() {
  setTimeout(function() {
    connect(true);
  }, rand10to60());
}

function basePacket(event, extra) {
  return _.extend({
    type: "desktop",
    event: event,
    date: Date.now(),
    hostname: hostname,
    hostType: hostType,
    devices: devices
  }, extra);
}

function connect(reconnect) {

  if (reconnect) {
    console.log("Reconnecting to " + config.host + ":" + config.tcpPort);
  }
  else {
    console.log("Connecting to " + config.host + ":" + config.tcpPort);
  }

  var client = net.connect(config.tcpPort, config.host);
  var loopTimer;
  var keepAliveTimer;
  function keepAlive(){
    clearTimeout(keepAliveTimer);
    keepAliveTimer = setTimeout(function() {
      client.destroy(); // Will emit 'close' event which launches reconnection...
      console.error("Ping timeout. Reconnecting...");
    }, PING_TIMEOUT);
  }

  client.on("connect", function() {
    console.info("Connection ok!");
    if (reconnect) {
      console.info("This is a reconnection");
    }

    getXUser(function(err, user) {
      if (err) {
        console.error("Failed to determine current user");
        return;
      }

      /**
       * Timeout loop monitoring user currently logged in.
       **/
      var currentUser;
      (function loginLoop() {
        getXUser(function(err, username) {
          if (err) console.error("Failed to determine current user", err);

          // Act on change
          if (!err && username !== currentUser) {

            // Ignore username completely here to keep statistics anonymoys
            if (username) {
              console.log("User is logged in");
              client.write(JSON.stringify(basePacket("login")) + "\n");
            }
            else {
              console.log("User is now logged out");
              client.write(JSON.stringify(basePacket("logout")) + "\n");
            }

            currentUser = username;
          }

          // two minute loop
          loopTimer = setTimeout(loginLoop, 60 * 1000);
        });
      }());

      var packet = basePacket("bootend");
      if (reconnect) packet.reconnect = true;
      client.write(JSON.stringify(packet) + "\n");

    });
  });

  client.on("close", function() {
    clearTimeout(loopTimer);
    console.log("Connection closed. Reconnecting soon.");
    retry();
  });

  client.on("error", function(err) {
    console.log("Connection Error", err);
  });


  keepAlive();
  client.pipe(new JSONStream()).on("data", function(packet) {
    if (packet.type === "internal" && packet.event === "ping") {
      keepAlive();
      client.write(JSON.stringify({
        type: "internal",
        event: "pong"
      }) + "\n");
    }
  });

}

lock(config.lockFile || "/tmp/puavo-monitor.lock", function(err) {
  if (err && err.code === "FLOCK_TIMEOUT") {
    console.error("puavo-monitor is already running");
    process.exit(1);
  }
  else if (err) throw err;

  console.info("puavo-monitor started",
    JSON.stringify({ hostType: hostType, hostname: hostname, pid: process.pid })
  );
  connect();
});
