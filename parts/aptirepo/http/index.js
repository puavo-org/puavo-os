
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
var mkdirp = Q.denodeify(require("mkdirp"));

function promiseConcat(stream) {
    return Q.promise(function(resolve, reject) {
        stream.on("error", reject);
        stream.pipe(concat(resolve));
    });
}

var app = express();

var config = [
    __dirname + "/aptirepo-http.json",
    "/etc/aptirepo/http.json",
    "~/.config/aptirepo-http.json"
].reduce(function(memo, configPath) {
    var config;
    try {
        config = require(configPath);
    } catch (err) {
        return memo;
    }
    return xtend(memo, config);
}, {
    aptirepo: "/srv/aptirepo"
});


function aptirepoImport(changesFilePath, branch) {
    branch = branch.toString();
    var aptirepoRootDir = path.join(config.aptirepo, branch);
    return mkdirp(aptirepoRootDir).then(function() {
        return Q.promise(function(resolve, reject) {

            var child = spawn("aptirepo-import", [changesFilePath], {
                env: xtend({
                    APTIREPO_CONFDIR: "/etc/aptirepo",
                    APTIREPO_ROOTDIR: aptirepoRootDir
                }, process.env)
            });

            child.on("error", reject);
            child.on("close", resolve);
            child.stdout.pipe(process.stdout);
            child.stderr.pipe(process.stderr);

        });
    });

}

app.get("/", function(req, res) {
    res.sendfile(__dirname + "/index.html");
});

app.post("/", function(req, res) {

    var form = new multiparty.Form();
    form.on("error", function(err) {
        res.write("aptirepo-http: Failed to parse multipart post");
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
        console.log("got part", part.name);
        if (part.name === "branch") {
            repoBranch.resolve(promiseConcat(part));
            return;
        }

        if (part.filename) {
            files.push(tmpDir.then(function(dirPath) {
                var outPath = path.join(dirPath, part.filename);
                if (part.name === "changes") {
                    changesFilePath.resolve(outPath);
                }
                console.log("Receiving", part.name, "to", outPath);
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
                .spread(aptirepoImport);
        }).then(function(commandOutput) {
            console.log("Upload ok", commandOutput);
            res.json(commandOutput);
        }, function(err) {
            console.error("Upload failed", err);
            res.json({ error: err.message }, 400);
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
