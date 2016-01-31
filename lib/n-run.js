var async = require('async');
var semver = require('semver');
var isRange = require('is-semver-range');
var n = require('n-wrap');
var isIo = require('is-io-version');
var npm = require('npm');
var install = require('n-install-missing');
var installed = require('n-installed');
var _ = require('lodash');
require('lodash-aliases');
var listify = require('listify');
var chalk = require('chalk');
var pluralize = require('pluralize');

var run = function(command, versions, opts, fn) {
  // Get a string, loggable version of the command
  var cmd = command.join(' ');
  // Run the versions in series so that the logging doesn't get muddled together
  async.eachSeries(versions, function(version, next) {
    // Log useful stuff unless logging is suppressed
    if (!opts.quiet) {
      console.log();
      console.log('Executing', cmd, 'on version', chalk.green(version));
    }
    // Execute the command against the binary
    (isIo(version) ? n.io : n).use(version, command, next);
  }, function(err) {
    // Again, log if appropriate
    if (!opts.quiet) {
      if (err) {
        console.log();
        console.log(cmd, 'failed on one or more versions of node');
        console.log(err);
      } else {
        console.log();
        console.log(cmd, 'completed successfully in node versions', listify(versions));
      }
    }
    // Call back
    fn(err);
  });
};

var resolve = function(versions, results, fn) {
  versionList = results.node.concat(results.io);
  // Resolve any version that isn't an exact version
  versions = _.map(versions, function(version) {
    return isRange(version) ? semver.maxSatisfying(versionList, version) : version;
  });
  fn(null, versions);
};

var filter = function(results, opts, fn) {
  var installedVersions = results.installed.node.concat(results.installed.io);
  var origResolved = _.clone(results.resolve);
  results.resolve = _.intersection(results.resolve, installedVersions);
  var notInstalled = _.difference(origResolved, installedVersions);
  if (!opts.quiet && notInstalled.length) {
    console.log();
    console.log(pluralize('Version', notInstalled.length), listify(notInstalled), 'is not installed. Skipping . . .');
  }
  fn();
};

var globalize = function(command, fn) {
  // Prefix the first part of the command with the global bin path
  command[0] = npm.config.prefix + '/bin/' + command[0];
  fn(null, command);
};

exports.run = function(command, versions, opts, fn) {
  if (typeof opts === 'function') {
    fn = opts;
    opts = {};
  }

  // Gather options
  opts = _.defaults(opts, { install: true, global: false, quiet: false });
  command = typeof command === 'string' ? command.split(' ') : command;

  // Determine ahead of time if we need to resolve any semver ranges
  var needsResolved = _.any(versions, isRange);

  async.auto({
    // Get versions of node
    node: function(next) {
      return needsResolved ? n.ls(next) : next();
    },
    // Get versions of io.js
    io: function(next) {
      return needsResolved ? n.io.ls(next) : next();
    },
    // Get installed node and io.js versions
    installed: function(next) {
      return opts.install ? next() : installed(next);
    },
    // Resolve any semver ranges
    resolve: ['node', 'io', 'installed', function(next, results) {
      return needsResolved ? resolve(versions, results, next) : next(null, versions);
    }],
    // Install any missing node binaries
    install: ['resolve', function(next, results) {
      return opts.install ? install(results.resolve, opts, next) : filter(results, opts, next); 
    }],
    // Load the npm config so we can get a reliable global path
    npm: function(next) {
      return opts.global ? npm.load({ global: true }, next) : next();
    },
    // Prefix the command with the global npm path
    globalize: ['npm', function(next) {
      return opts.global ? globalize(command, next) : next(null, command);
    }]
  }, function(err, results) {
    if (err) {
      // Stop on error
      fn(err);
    } else {
      // Run the command against the node versions
      run(results.globalize, results.resolve, opts, fn);
    }
  });
};
