[![Build Status](https://travis-ci.org/tandrewnichols/n-run.png)](https://travis-ci.org/tandrewnichols/n-run) [![downloads](http://img.shields.io/npm/dm/n-run.svg)](https://npmjs.org/package/n-run) [![npm](http://img.shields.io/npm/v/n-run.svg)](https://npmjs.org/package/n-run) [![Code Climate](https://codeclimate.com/github/tandrewnichols/n-run/badges/gpa.svg)](https://codeclimate.com/github/tandrewnichols/n-run) [![Test Coverage](https://codeclimate.com/github/tandrewnichols/n-run/badges/coverage.svg)](https://codeclimate.com/github/tandrewnichols/n-run) [![dependencies](https://david-dm.org/tandrewnichols/n-run.png)](https://david-dm.org/tandrewnichols/n-run)

# n-run

Run a command against a series of node versions using n

## Installation

`npm install --save n-run`

## Summary

`n-run` takes a command to run, a list of versions (or semver ranges) to run it against, optionally an options object, and a callback to execute when finished.

## Usage

The command can be a string like `./index.js --foo bar`. The command will be split on spaces and passed to `child_process.spawn`, thus it's safer to pass `command` as an array to prevent splitting incorrectly (e.g. something like `./index.js --message "A message with spaces in it"`).

The list of versions is an array of node and/or io.js versions. These can also be semver ranges (so if you want to run the command against _any_ node v4 binary, passing "4" is sufficient); By default, `n-run` will select the highest version of node or io.js matching the range that is already installed and skip the version if there isn't one matching. You can override this with the `install` option below.

The options hash may contain any of the following options (all of which default to `false`).

* install: Setting this option to true will cause versions not installed to be installed. This could be either a specific version not already installed or a range which no installed version satisfies. Setting this option to 'latest' will install the latest version matching a range even if another version already installed would satisfy the range. Ex. Assuming you have version `4.0.0` installed, running a command against `4.0.0` and `5.0.0` with `install: true` will install `5.0.0`. Running the command against `4` and `5` with `install: true` will install the latest version of `5.x`. Running the command against `4` and `5` with `install: 'latest'` will install the latest versions of both `4.x` and `5.x`.
* quiet: Do not log anything.
* global: If `true`, the first part of the command will be prefixed with the global npm binary path. In other words, if you want to run a command that requires `npm install -g`, add `global: true` to your options (e.g. `grunt`, `gulp`, `yo`, etc.). This let's you pass the command as (for example) `grunt build` (which would normally fail when run with `n use <version>`). If you need something _other_ than first part of the command to be prefixed, you can just do it yourself. It's probably safe to use `process.env.N_PREFIX + '/bin/'` unless you've modified that variable. This library uses the [npm module](https://www.npmjs.com/package/npm) to load the global config just in case, but this is an asynchronous operation, so you should probably prefer environment variables when available.

## Examples

Run a command against a couple binaries.

```js
var n = require('n-run');
n.run('foo bar', ['4.2.6', '5.5.0'], function(err) {
  // if err is null, the the command "foo bar" was successfully run against all node versions supplied
});
```

Run a command, but resolve to the most recent matching node versions first.

```js
var n = require('n-run');
n.run('foo bar', ['4', '5'], function(err) {
  // if err is null, the the command "foo bar" was successfully run against all node versions supplied
});
```

Run a global command.

```js
var n = require('n-run');
n.run('grunt fooBar', ['4.2.6', '5.5.0'], { global: true }, function(err) {
  // if err is null, the the command "foo bar" was successfully run against all node versions supplied
});
```

Do not log anything or install missing binaries.

```js
var n = require('n-run');
n.run('foo bar', ['4.2.6', '5.5.0'], { quiet: true, install: false }, function(err) {
  // if err is null, the the command "foo bar" was successfully run against all node versions supplied
});
```

## Testing your .travis build matrix

The use case I built n-run for was local testing against a travis build matrix. If you use grunt for tests, you can install [grunt-test-matrix](https://github.com/tandrewnichols/grunt-test-matrix) and add configuration like:

```
grunt.initConfig({
  testMatrix: {
    mocha: {
      task: ['mocha:unit', 'mocha:integration']
    }
  }
});
```

If you use gulp, there isn't a specific plugin, since this isn't exactly a stream-compatible operation, but it's simple to do in a task by installing this and [travis-yaml](https://github.com/tandrewnichols/travis-yaml) and adding this (tested) code:

```
var gulp = require('gulp');
var n = require('n-run');
var travisYaml = require('travis-yaml');

gulp.task('run', function(done) {
  travisYaml(function(err, travis) {
    var versions = travis.node_js;
    /*
     * If you include any versions of io.js in your build,
     * enable this block to map the "iojs-v2" style version
     * to one usable by n-run
     */
    //versions = versions.map(function(version) {
      //return version.replace('iojs-v', '');
    //});

    // Replace "unit" with your testing task.
    n.run(['gulp', 'unit'], versions, { global: true }, done);

    /*
     * If you install gulp locally as a dependency, use this line
     * instead of the one above, so that n can find the gulp binary.
     */
    //n.run(['./node_modules/.bin/gulp', 'unit'], versions, done);
  });
});
```

## Contributing

Please see [the contribution guidelines](CONTRIBUTING.md).
