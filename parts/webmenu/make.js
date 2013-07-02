var fs = require("fs");
var path = require("path");

var browserify = require("browserify");
var coffee = require("coffee-script");
var stylus = require("stylus");
var nib = require("nib");
var sh = require("shelljs");

exports.coffee = function() {
    console.log("coffee");
    sh.ls("src/*.coffee").forEach(function(file) {
        var out = path.basename(file);
        out = out.replace(/coffee$/, "js");
        out = "lib/" +  out;
        coffee.compile(sh.cat(file), {bare: true}).to(out);
    });
};

exports.copy_modules = function() {
    console.log("copy_modules");
    sh.cp("-f", "src/*.js", "lib/");
};

exports.browserify = function(opts) {
    console.log("browserify");
    var b = browserify("./scripts/main.coffee");
    b.transform(require("hbsfy"));
    b.transform(require("coffeeify"));
    b.bundle({ debug: opts.debug }).pipe(fs.createWriteStream("bundle.js"));
};

exports.stylus = function() {
    console.log("stylus");
    stylus(sh.cat("styles/main.styl"))
        .set("paths", [__dirname + "/styles"])
        .use(nib())
        .render(function(err, css) {
            if (err) throw err;
            css.to("styles/main.css");
        });
};

exports.all = function(opts) {
    console.log("all");
    exports.copy_modules(opts);
    exports.coffee(opts);
    exports.browserify(opts);
    exports.stylus(opts);
};

if (require.main === module) {
    var argv = require('optimist')
        .alias('d', 'debug')
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
