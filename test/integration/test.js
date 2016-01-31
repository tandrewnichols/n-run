#!/usr/bin/env node

var fs = require('fs');
var str = process.version;
console.log(str);

fs.stat(__dirname + '/output.txt', function(err, stat) {
  console.log('FS.STAT', err);
  if (!err) {
    str = '\n' + str;
  }
  fs.appendFile(__dirname + '/output.txt', str, function(err) {
    console.log('FS.APPENDFILE', err);
    if (err) {
      process.exit(1);
    } else {
      process.exit();
    }
  });
});
