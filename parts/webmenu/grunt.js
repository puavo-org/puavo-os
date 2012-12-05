module.exports = function(grunt) {
  grunt.loadNpmTasks("grunt-stylus");
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

    watch: {
      files: "content/**",
      tasks: "default"
    }

  });

  grunt.registerTask("default", "stylus");
};
