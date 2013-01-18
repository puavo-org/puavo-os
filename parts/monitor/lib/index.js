
var os = require("os");
var net = require("net");
var config = require("/etc/puavo-monitor.json");
var _ = require("underscore");


var hostname = os.hostname();
var devices = require("./devices");
var getXUser = require("./user");

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
    devices: devices
  }, extra);
}

function connect(reconnect) {

  var client = net.connect(config.tcpPort, config.host);
  var timer;

  client.on("connect", function() {
    console.log("Connected to " + config.host + ":" + config.tcpPort +
      ". Reconnect: " + reconnect);

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
              console.log("User logged in", username);
              client.write(JSON.stringify(basePacket("login")) + "\n");
            }
            else {
              console.log("User logged out", currentUser);
              client.write(JSON.stringify(basePacket("logout")) + "\n");
            }

            currentUser = username;
          }

          // Just always send a ping to keep the connection alive.
          client.write(JSON.stringify("ping") + "\n");

          // two minute loop
          timer = setTimeout(loginLoop, 60 * 2 * 1000);
        });
      }());

      var packet = basePacket("bootend");

      if (reconnect) {
        packet.reconnect = true;
        console.log("reconnecting");
      }

      client.write(JSON.stringify(packet) + "\n");

    });
  });

  client.on("close", function() {
    clearTimeout(timer);
    console.log("Connection closed. Reconnecting soon.");
    retry();
  });

  client.on("error", function(err) {
    clearTimeout(timer);
    console.log("Connection failed. Reconnecting soon.");
    retry();
  });

}

connect();
