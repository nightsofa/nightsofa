module.exports = function(grunt) {

	grunt.initConfig({

    pkg : grunt.file.readJSON('package.json'),

    coffee: {
      compile: {
        files: {
          'scripts/app.js': 'src/app.coffee'
        }
      }
    },

    uglify: {
      production: {
        files: {
          'scripts/libs/jquery.autocomplete.min.js' : ['scripts/libs/jquery.autocomplete.js'],
          'scripts/app.min.js' : ['scripts/app.js']
        }
      }
    },

    jshint: {
      options: {
        globals: {
          jQuery: true
        }
      },
    	files: ['Gruntfile.js'] //'scripts/app.js'
    },

    less: {
      production: {
        options:{

        },
        files: {
          'styles/style.css': ['src/style.less']
        }
      }
    },

    cssmin: {
    	compress: {
    		files: {
    			'styles/style.min.css' : ['styles/style.css']
    		}
    	}
    }

  });


  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-coffee');

  grunt.registerTask('js', ['coffee', 'uglify', 'jshint']);
  grunt.registerTask('css', ['less', 'cssmin']);
  grunt.registerTask('default', ['js', 'css']);


};
