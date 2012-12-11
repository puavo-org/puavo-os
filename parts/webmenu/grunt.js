/*jshint node:true*/
module.exports = function(grunt) {
  var pkg = require("./package.json");
  grunt.loadNpmTasks("grunt-stylus");
  grunt.loadNpmTasks("grunt-contrib-yuidoc");
  grunt.loadNpmTasks("grunt-mocha");
  grunt.initConfig({

    stylus: {
      compile: {
        options: {
          'include css': true,
          'paths': ["theme/css/"]
        },
        files: {
          'theme/css/master.css': 'theme/css/master.styl'
        }
      }
    },

    yuidoc: {
      compile: {
        name: pkg.name,
        description: pkg.description,
        version: pkg.version,
        url: "https://github.com/opinsys/webmenu",
        options: {
          quiet: false,
          syntaxtype: "coffee",
          extension: ".coffee",
          paths: [
            "scripts/app/",
            "lib/"
          ],
          outdir: "./out"
        }
      }
    },

    mocha: {
      client: {
        src: [ "tests.html" ]

      }
    },

    watch: {
      files: "theme/**",
      tasks: "stylus"
    }

  });

  grunt.registerTask("default", "stylus yuidoc");
};
