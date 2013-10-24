
var args = require("./args");
var exec = require("child_process").exec;
var express = require("express");
var http = require("http");
var multiparty = require("multiparty");
var path = require("path");
var Q = require("q");
var os = require("os");
var temp = require("temp");
var xtend = require("xtend");
var fs = require("fs");
var promisePipe = require("promisepipe");

Q.longStackSupport = true;
var mkTmpDir = Q.denodeify(temp.mkdir);
var rimraf = Q.denodeify(require("rimraf"));

var app = express();

var config = [
    __dirname + "/debbox.json",
    "/etc/debbox.json",
    "~/.config/debbox.json"
].reduce(function(memo, configPath) {
    var config;
    try {
        config = require(configPath);
    } catch (err) {
        return memo;
    }
    return xtend(memo, config);
}, {});


function debExec(debPath) {
    var command = config.debCommand.replace(/\$1/g, "'" + debPath + "'");
    return Q.promise(function(resolve, reject) {
        console.log("Executing", command);
        exec(command, function(err, stdout, stderr) {
            var res = {
                file: debPath,
                command: command,
                stdout: stdout,
                stderr: stderr
            };
            if (err) reject(xtend(res, {error: err}));
            else resolve(res);
        });

    });
}

app.get("/", function(req, res) {
    res.sendfile(__dirname + "/index.html");
});

app.post("/deb", function(req, res) {

    var form = new multiparty.Form();
    form.on("error", function(err) {
        res.write("debbox: Failed to parse multipart post");
        res.end("\n", 400);
    });

    var tmpDir = mkTmpDir({
        dir: path.join(os.tmpDir()),
        prefix: "debupload"
    });

    var jobs = [];

    form.on("part", function(part) {
        console.log("Got file", part.filename);
        jobs.push(tmpDir.then(function(dirPath) {
            var outPath = path.join(dirPath, part.filename);
            return promisePipe(part, fs.createWriteStream(outPath))
                .then(function() {
                    return debExec(outPath);
                });
        }));

    });


    form.on("close", function() {

        Q.all(jobs).then(function(commandOutput) {
            console.log("Upload ok", commandOutput);
            res.json(commandOutput);
        }, function(err) {
            console.error("Upload failed", err);
            res.json(err, 400);
        }).finally(function() {
            return tmpDir.then(rimraf).fail(function(err) {
                console.error("Failed to remove temp dir", err);
            });
        }).done();
    });

    form.parse(req);
});

var server = http.createServer(app);
server.listen(Number(args.port) || 8080, function() {
    console.log("Listening on", server.address().port);
});
