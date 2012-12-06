/*jshint node:true*/
module.exports = function(grunt) {
  var pkg = require("./package.json");
  grunt.loadNpmTasks("grunt-stylus");
  grunt.loadNpmTasks("grunt-contrib-yuidoc");
  grunt.initConfig({

    stylus: {
      compile: {
        options: {
          'include css': true,
          'paths': ["content/theme/css/"]
        },
        files: {
          'content/theme/css/master.css': 'content/theme/css/master.styl'
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
            "content/scripts/app/",
            "lib/"
          ],
          outdir: "./out"
        }
      }
    },


    watch: {
      files: "content/**",
      tasks: "stylus"
    }

  });

  grunt.registerTask("default", "stylus yuidoc");
};
