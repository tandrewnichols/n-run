#!/usr/bin/env node

var fs = require('fs');
var str = process.version;

fs.stat(__dirname + '/output.txt', function(err, stat) {
  if (!err) {
    str = '\n' + str;
  }
  fs.appendFile(__dirname + '/output.txt', str, function(err) {
    if (err) {
      process.exit(1);
    } else {
      process.exit();
    }
  });
});
