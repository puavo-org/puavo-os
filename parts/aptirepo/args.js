
var optimist = require("optimist");

var args= optimist
    .usage("Start debbox.\n\nUsage: $0")
    .alias("p", "port")
    .describe("p", "Port to listen")

    .alias("h", "help")
    .argv;

if (args.help) {
    optimist.showHelp();
    process.exit(0);
}


module.exports = args;
