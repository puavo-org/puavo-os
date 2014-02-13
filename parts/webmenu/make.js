var fs = require("fs");
var path = require("path");

var coffee = require("coffee-script");
var nib = require("nib");
var sh = require("shelljs");
process.chdir(__dirname);

function browserifyBuild(entry, out, opts) {
    var brwsrf = opts.watch ? require("watchify") : require("browserify");
    var b = brwsrf(entry);
    b.transform(require("hbsfy"));

    b.transform({
        minify: false,
        linenos: true,
        configure: function(stylus) {
            stylus.use(nib());
        }
    }, require("stylify"));

    b.transform(require("coffeeify"));

    function bundle() {
        var started = Date.now();
        b.bundle({ debug: opts.debug })
        .pipe(fs.createWriteStream(out))
        .on("close", function() {
            console.log(out, "build in", Date.now() - started, "ms");
        });
    }

    if (opts.watch) console.log("listening on ", entry);
    b.on("update", bundle);
    bundle();
    return bundle;
}

exports.coffee = function() {
    console.log("coffee");
    sh.mkdir("-p", "lib");
    sh.ls("src/*.coffee").forEach(function(file) {
        var out = path.basename(file);
        out = out.replace(/coffee$/, "js");
        out = "lib/" +  out;
        coffee.compile(sh.cat(file), {bare: true}).to(out);
    });
    sh.cp("-f", "src/*.js", "lib/");
};



exports.browserify = function(opts) {
    console.log("browserify");
    browserifyBuild("./scripts/main.coffee", "bundle.js", opts);
};

exports.browserify_test = function(opts) {
    console.log("browserify_test");
    browserifyBuild("./scripts/tests/index.coffee", "./scripts/tests/bundle.js", opts);
};

exports.all = function(opts) {
    console.log("all");
    exports.coffee(opts);
    exports.browserify(opts);
    exports.browserify_test(opts);
    exports.i18n(opts);
};

exports.i18n = function() {
    require("coffee-script");
    require("./extra/i18nUpdate")();
};

if (require.main === module) {
    var argv = require('optimist')
        .alias("d", "debug")
        .alias("w", "watch")
        .argv;

    if (argv._.length) {
        argv._.forEach(function(task) {
            exports[task](argv);
        });
    }
    else {
        exports.all(argv);
    }
}
