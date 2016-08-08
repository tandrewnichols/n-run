var async = require('async');
var semver = require('semver');
var isRange = require('is-semver-range');
var n = require('n-wrap');
var isIo = require('is-io-version');
var npm = require('npm');
var install = require('n-install-missing');
var installed = require('n-installed');
var _ = require('lodash');
_.mixin({ any: _.some });
var listify = require('listify');
var chalk = require('chalk');
var pluralize = require('pluralize');

var run = function(results, opts, fn) {
  // Get a string, loggable version of the command
  var cmd = results.command.join(' ');
  // Sort versions, so that they run roughly oldest to newest
  var versions = results.versions.sort();
  // Run the versions in series so that the logging doesn't get muddled together
  async.eachSeries(results.versions, function(version, next) {
    // Log useful stuff unless logging is suppressed
    if (!opts.quiet) {
      console.log();
      console.log('Executing', cmd, 'on version', chalk.green(version));
    }
    // Execute the command against the binary
    (isIo(version) ? n.io : n).use(version, results.command, next);
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

var resolve = function(versions, results, opts, fn) {
  versions = _.map(versions, function(version) {
    if (opts.install) {
      var versionList = results.node.concat(results.io);
      if (opts.install === 'latest') {
        return isRange(version) ? semver.maxSatisfying(versionList, version) : version;
      } else {
        return isRange(version) ? semver.maxSatisfying(results.installed.all, version) || semver.maxSatisfying(versionList, version) : version;
      }
    } else {
      var v = isRange(version) ? semver.maxSatisfying(results.installed.all, version) : version;
      if (!v) {
        console.log('No version matching', version, 'is installed. Skipping . . .');
      }
      return v;
    }
  }).filter(Boolean);

  fn(null, versions);
};

var globalize = function(command, fn) {
  // Prefix the first part of the command with the global bin path
  command[0] = npm.config.prefix + '/bin/' + command[0];
  fn(null, command);
};

var noop = function(next) {
  next();
};

var filter = function(versions, results, opts, next) {
  versions = _.filter(versions, function(version) {
    if (!opts.install && results.installed.all.indexOf(version) === -1) {
      console.log('No version matching', version, 'is installed. Skipping . . .');
      return false;
    }
    return true;
  });
  next(null, versions);
};

var setup = function(command, versions, opts, fn) {
  // Determine ahead of time if we need to resolve any semver ranges
  var needsResolved = _.any(versions, isRange);
  async.auto({
    // Get versions of node
    node: needsResolved && opts.install ? n.ls : noop,
    // Get versions of io.js
    io: needsResolved && opts.install ? n.io.ls : noop,
    // Get installed node and io.js versions
    installed: installed,
    // Resolve any semver ranges
    versions: ['node', 'io', 'installed', function(next, results) {
      return needsResolved ? resolve(versions, results, opts, next) : filter(versions, results, opts, next);
    }],
    // Install any missing node binaries
    install: ['versions', function(next, results) {
      return opts.install ? install(results.versions, opts, next) : next(); 
    }],
    // Load the npm config so we can get a reliable global path
    npm: function(next) {
      return opts.global ? npm.load({ global: true }, next) : next();
    },
    // Prefix the command with the global npm path
    command: ['npm', function(next) {
      return opts.global ? globalize(command, next) : next(null, command);
    }]
  }, function(err, results) {
    return err ? fn(err) : run(results, opts, fn);
  });
};

exports.run = function(command, versions, opts, fn) {
  if (typeof opts === 'function') {
    fn = opts;
    opts = {};
  }

  // Gather options
  opts = _.defaults(opts, { install: false, global: false, quiet: false });
  command = typeof command === 'string' ? command.split(' ') : command;

  setup(command, versions, opts, fn);
};
