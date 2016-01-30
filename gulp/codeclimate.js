var gulp = require('gulp');
var codeclimate = require('gulp-codeclimate-reporter');

gulp.task('codeclimate', function() {
  if (process.version.indexOf('v4') > -1) {
    gulp.src('coverage/lcov.info', { read: false })
      .pipe(codeclimate({
        token: '25cf1c15d09998494502339eb682bacb7a96a12eb985e54b3dcae5a002c8ee98'
      }));
  }
});

