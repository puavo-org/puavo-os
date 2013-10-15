
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
var promiseFromStream = require("./promiseFromStream");

Q.longStackSupport = true;
var mkTmpDir = Q.denodeify(temp.mkdir);
var rimraf = Q.denodeify(require("rimraf"));

var app = express();

var config = [
    "/etc/debbox.json",
    __dirname + "/debbox.json",
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

        var child = exec(command).on("exit", function(exitcode) {
            if (exitcode === 0) resolve();
            else reject(new Error("Nonzero exit code: " + exitcode));
        }).on("error", reject);

        child.stdout.pipe(process.stdout);
        child.stderr.pipe(process.stderr);

    }).fail(function(err) {
        err.command = command;
        return Q.reject(err);
    });
}

app.get("/", function(req, res) {
    res.sendfile(__dirname + "/index.html");
});

app.post("/deb", function(req, res) {

    var form = new multiparty.Form();
    form.on("error", function(err) {
        return res.send("Failed to parse your data", 400);
    });

    var tmpDir = mkTmpDir({
        dir: path.join(os.tmpDir()),
        prefix: "debupload"
    });

    var jobs = [];

    form.on("part", function(part) {
        console.log("part", part.name, part.filename, part.headers);
        jobs.push(promiseFromStream(part));

        jobs.push(tmpDir.then(function(dirPath) {
            var outPath = path.join(dirPath, part.filename);
            return promiseFromStream(part.pipe(fs.createWriteStream(outPath)))
                .then(function() {
                    return debExec(outPath);
                });
        }));

    });


    form.on("close", function() {
        Q.all(jobs).then(function() {
            res.send("ok");
        }, function(err) {
            console.error("Upload failed", err);
            res.send(err.message, 400);
        }).finally(function() {
            tmpDir.then(function(dirPath) {
                return rimraf(dirPath);
            }).fail(function(err) {
                console.error("Failed to remove temp dir", err);
            });
        });
    });

    form.parse(req);
});

var server = http.createServer(app);
server.listen(Number(args.port) || 8080, function() {
    console.log("Listening on", server.address().port);
});
