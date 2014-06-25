module.exports = function(grunt) {

	grunt.initConfig({

    pkg : grunt.file.readJSON('package.json'),

    coffee: {
      compile: {
        files: {
          'scripts/app.js': 'scripts/app.coffee'
        }
      }
    },

    uglify: {
      production: {
        files: {
          'scripts/libs/jquery.autocomplete.min.js' : ['scripts/libs/jquery.autocomplete.js'],
          'dist/scripts/app.min.js' : ['scripts/app.js']
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
          'styles/style.css': ['styles/style.less']
        }
      }
    },

    cssmin: {
    	compress: {
    		files: {
    			'dist/styles/style.min.css' : ['styles/style.css']
    		}
    	}
    },
    
    copy: {
      main: {
        files: [
          { expand: true, src: ['scripts/libs/*.min.js'], dest: 'dist/' },          
          { expand: true, src: ['*.html'], dest: 'dist/', filter: 'isFile' },
          { expand: true, src: ['images/*'], dest: 'dist/' }
        ]
      }
    },
    
    'gh-pages': {
      options: {
        base: 'dist'
      },
      src: '**'
    }    

  });


  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-gh-pages');
  grunt.loadNpmTasks('grunt-contrib-copy');

  grunt.registerTask('js', ['coffee', 'uglify', 'jshint']);
  grunt.registerTask('css', ['less', 'cssmin']);
  grunt.registerTask('default', ['js', 'css']);
  grunt.registerTask('golive', ['default', 'copy', 'gh-pages']);


};
