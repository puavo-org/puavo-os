/*jshint node:true*/
module.exports = function(grunt) {
  var pkg = require("./package.json");
  grunt.loadNpmTasks("grunt-stylus");
  grunt.loadNpmTasks("grunt-mocha");
  grunt.initConfig({

    stylus: {
      compile: {
        options: {
          'include css': true,
          'paths': ["styles/"]
        },
        files: {
          'styles/main.css': 'styles/main.styl'
        }
      }
    },

    mocha: {
      client: {
        src: [ "tests.html" ]

      }
    },

    watch: {
      files: "styles/**",
      tasks: "stylus"
    }

  });

  grunt.registerTask("default", "stylus");
};
