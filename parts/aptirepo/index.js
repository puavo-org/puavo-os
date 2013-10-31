
var args = require("./args");
var spawn = require("child_process").spawn;
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
var concat = require("concat-stream");

Q.longStackSupport = true;
var mkTmpDir = Q.denodeify(temp.mkdir);
var rimraf = Q.denodeify(require("rimraf"));

function promiseConcat(stream) {
    return Q.promise(function(resolve, reject) {
        stream.on("error", reject);
        stream.pipe(concat(resolve));
    });
}

var app = express();

app.use("/packages", express.static("/var/local/debbox/packages"));
app.use("/packages", express.directory("/var/local/debbox/packages"));

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


function command(changesFilePath, branch) {

    return Q.promise(function(resolve, reject) {

        var child = spawn("aptirepo-import", ["-b", branch, changesFilePath], {
            env: xtend({
                APTIREPO_ROOT: config.aptirepo
            }, process.env)
        });

        child.on("error", reject);
        child.on("close", resolve);
        child.stdout.pipe(process.stdout);
        child.stderr.pipe(process.stderr);

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

    var files = [];

    var changesFilePath = Q.defer();
    var repoBranch = Q.defer();


    form.on("part", function(part) {
        if (part.name === "branch") {
            repoBranch.resolve(promiseConcat(part));
            return;
        }

        if (part.filename) {
            console.log("Got file", part.name, part.filename);
            files.push(tmpDir.then(function(dirPath) {
                var outPath = path.join(dirPath, part.filename);
                if (part.name === "changes") {
                    changesFilePath.resolve(outPath);
                }
                return promisePipe(part, fs.createWriteStream(outPath));
            }));
        } else {
            console.error("Unknown field", part.name, part.filename);
        }

    });


    form.on("close", function() {

        Q.all(files).then(function() {
            return Q.all([changesFilePath.promise, repoBranch.promise])
                .timeout(100, "changes file or branch missing")
                .spread(command);
        }).then(function(commandOutput) {
            console.log("Upload ok", commandOutput);
            res.json(commandOutput);
        }, function(err) {
            console.error("Upload failed", err);
            res.json({ error: err.message }, 400);
        }).finally(function() {
            return tmpDir.then(function(p) {
                console.log("REMOVING!!!!!!!!", p);
            }).fail(function(err) {
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
