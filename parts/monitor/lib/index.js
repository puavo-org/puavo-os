
var os = require("os");
var net = require("net");
var config = require("/etc/puavo-monitor.json");

var hostname = os.hostname();
var devices = require("./devices");

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

function connect(reconnect) {

  var client = net.connect(config.tcpPort, config.host);
  var interval;

  client.on("connect", function() {
    console.log("Connected to " + config.host + ":" + config.tcpPort + ". Reconnect: " + reconnect);
    var packet = {
      type: "desktop",
      event: "bootend",
      date: Date.now(),
      hostname: hostname,
      devices: devices
    };

    if (reconnect) {
      packet.reconnect = true;
      console.log("reconnecting");
    }

    // Write ping messages to keep connection alive
    interval = setInterval(function() {
      client.write(JSON.stringify("ping") + "\n");
    }, 10 * 1000);

    client.write(JSON.stringify(packet) + "\n");
  });

  client.on("close", function() {
    clearInterval(interval);
    console.log("Connection closed. Reconnecting soon.");
    retry();
  });

  client.on("error", function(err) {
    clearInterval(interval);
    console.log("Connection failed. Reconnecting soon.");
    retry();
  });

}

connect();
