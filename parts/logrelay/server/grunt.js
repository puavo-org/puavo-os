/*global module:false*/
module.exports = function(grunt) {
  grunt.loadNpmTasks('grunt-contrib');
  grunt.loadNpmTasks('grunt-coffee');

  // Project configuration.
  grunt.initConfig({
    meta: {
      version: '0.1.0',
      banner: '/*! ltsp-event - v<%= meta.version %> - ' +
        '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
        '* http://github.com/opinsys/ltsp-events/\n' +
        '* Copyright (c) <%= grunt.template.today("yyyy") %> ' +
        'Opinsys Oy; GPLv2 */'
    },
    coffee: {
      app: {
        src:  "public/scripts/src/*",
        dest: "public/scripts/app/"
      }
    },
    stylus: {
      compile: {
        files: {
          "public/style.css": [ "styles/main.styl" ]
        }
      }
    },
    requirejs: {
      compile: {
        options: {
          baseUrl : "public/scripts",
          mainConfigFile: "public/scripts/app/main.js",
          name: "app/main",
          out: "public/scripts/app/bundle.js"
        }
      }
    },
    watch: {
      files: ["public/scripts/src/*", "styles/*"],
      tasks: "coffee stylus"
    }
  });

  // Default task.
  grunt.registerTask("default", "coffee stylus requirejs");

};
