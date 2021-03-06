sinon = require 'sinon'
async = require 'async'
chalk = require 'chalk'

describe 'n-run', ->
  Given -> @n =
    ls: sinon.stub()
    use: sinon.stub()
    io:
      ls: sinon.stub()
      use: sinon.stub()
  Given -> @npm =
    load: sinon.stub()
    config:
      prefix: '/banana'
  Given -> @installed = sinon.stub()
  Given -> @install = sinon.stub()
  Given -> @cb = sinon.stub()
  Given -> @subject = require('proxyquire').noCallThru() '../../lib/n-run',
    'n-wrap': @n
    npm: @npm
    'n-install-missing': @install
    'n-installed': @installed

  afterEach -> console.log.restore()
  Given -> sinon.stub console, 'log'

  # Make async call all callbacks synchronously
  afterEach -> async.setImmediate.restore()
  Given -> sinon.stub async, 'setImmediate'
  Given -> async.setImmediate.callsArg 0

  context 'command is string and install is true', ->
    Given -> @n.use.withArgs('4.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @n.io.use.withArgs('2.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @installed.callsArgWith 0, null, { all: ['2.0.0', '4.0.0'] }
    Given -> @install.withArgs(['2.0.0', '4.0.0'],
      install: true
      global: false
      quiet: false
    , sinon.match.func).callsArgWith 2, null
    When -> @subject.run 'foo bar', ['2.0.0', '4.0.0'], { install: true }, @cb
    Then ->
      @cb.calledWith(null).should.be.true()
      console.log.getCall(1).args.should.eql ['Executing', 'foo bar', 'on version', chalk.green('2.0.0')]
      console.log.getCall(3).args.should.eql ['Executing', 'foo bar', 'on version', chalk.green('4.0.0')]
      console.log.getCall(5).args.should.eql ['foo bar', 'completed successfully in node versions', '2.0.0 and 4.0.0']

  context 'errors', ->
    context 'async error', ->
      Given -> @installed.callsArgWith 0, null, { all: ['2.0.0', '4.0.0'] }
      Given -> @install.withArgs(['2.0.0', '4.0.0'],
        install: true
        global: false
        quiet: false
      , sinon.match.func).callsArgWith 2, 'error'
      When -> @subject.run 'foo bar', ['2.0.0', '4.0.0'], { install: true }, @cb
      Then ->
        @cb.calledWith('error').should.be.true()
        @n.use.called.should.be.false()
        @n.io.use.called.should.be.false()

    context 'n-run error', ->
      Given -> @installed.callsArgWith 0, null, { all: ['2.0.0', '4.0.0'] }
      Given -> @n.io.use.withArgs('2.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, 'error'
      Given -> @install.withArgs(['2.0.0', '4.0.0'],
        install: true
        global: false
        quiet: false
      , sinon.match.func).callsArgWith 2, null
      When -> @subject.run 'foo bar', ['2.0.0', '4.0.0'], { install: true }, @cb
      Then ->
        @cb.calledWith('error').should.be.true()
        console.log.getCall(1).args.should.eql ['Executing', 'foo bar', 'on version', chalk.green('2.0.0')]
        console.log.getCall(3).args.should.eql ['foo bar', 'failed on one or more versions of node']
    
  context 'command is array and install is false', ->
    Given -> @n.use.withArgs('4.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @n.io.use.withArgs('2.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @installed.callsArgWith 0, null, { all: ['2.0.0', '4.0.0'] }
    When -> @subject.run ['foo', 'bar'], ['2.0.0', '4.0.0'],
      quiet: true
    , @cb
    Then ->
      @cb.calledWith(null).should.be.true()
      @install.called.should.be.false()
      console.log.called.should.be.false()

  context 'command is array, install is false, and some binaries are missing', ->
    Given -> @n.use.withArgs('4.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @installed.callsArgWith 0, null, { all: ['4.0.0'] }
    When -> @subject.run ['foo', 'bar'], ['2.0.0', '4.0.0'], @cb
    Then ->
      @cb.calledWith(null).should.be.true()
      @n.io.use.called.should.be.false()
      @install.called.should.be.false()
      console.log.getCall(0).args.should.eql ['No version matching', '2.0.0', 'is installed. Skipping . . .']

  context 'semver ranges (and opts.global is true)', ->
    Given -> @installed.callsArgWith 0, null, { all: ['2.0.0', '4.0.0'] }
    Given -> @npm.load.callsArgWith 1, null
    Given -> @n.use.withArgs('4.0.0', ['/banana/bin/foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @n.io.use.withArgs('2.0.0', ['/banana/bin/foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @n.io.use.withArgs('3.0.0', ['/banana/bin/foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @install.withArgs(['2.0.0', '3.0.0', '4.0.0'],
      global: true
      install: true
      quiet: false
    , sinon.match.func).callsArgWith 2, null
    Given -> @n.ls.callsArgWith 0, null, ['4.0.0', '4.1.2', '4.4.0']
    Given -> @n.io.ls.callsArgWith 0, null, ['2.0.0', '2.2.0', '3.0.0']
    When -> @subject.run 'foo bar', ['2', '3', '4.0.0'], { global: true, install: true }, @cb
    Then ->
      @cb.calledWith(null).should.be.true()
      console.log.getCall(1).args.should.eql ['Executing', '/banana/bin/foo bar', 'on version', chalk.green('2.0.0')]
      console.log.getCall(3).args.should.eql ['Executing', '/banana/bin/foo bar', 'on version', chalk.green('3.0.0')]
      console.log.getCall(5).args.should.eql ['Executing', '/banana/bin/foo bar', 'on version', chalk.green('4.0.0')]
      console.log.getCall(7).args.should.eql ['/banana/bin/foo bar', 'completed successfully in node versions', '2.0.0, 3.0.0, and 4.0.0']

  context 'semver ranges with install false', ->
    Given -> @n.use.withArgs('4.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @installed.callsArgWith 0, null, { all: ['4.0.0'] }
    When -> @subject.run ['foo', 'bar'], ['2', '4.0.0'], @cb
    Then ->
      @cb.calledWith(null).should.be.true()
      @n.io.use.called.should.be.false()
      @install.called.should.be.false()
      console.log.getCall(0).args.should.eql ['No version matching', '2', 'is installed. Skipping . . .']

  context 'opts.install is "latest"', ->
    Given -> @npm.load.callsArgWith 1, null
    Given -> @n.use.withArgs('4.0.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @n.io.use.withArgs('2.2.0', ['foo', 'bar'], sinon.match.func).callsArgWith 2, null
    Given -> @installed.callsArgWith 0, null, { all: ['2.0.0', '4.0.0'] }
    Given -> @n.ls.callsArgWith 0, null, ['4.0.0', '4.1.2', '4.4.0']
    Given -> @n.io.ls.callsArgWith 0, null, ['2.0.0', '2.2.0']
    Given -> @install.withArgs(['2.2.0', '4.0.0'],
      global: false
      install: 'latest'
      quiet: false
    , sinon.match.func).callsArgWith 2, null
    When -> @subject.run ['foo', 'bar'], ['2', '4.0.0'], { install: 'latest' }, @cb
    Then ->
      @cb.calledWith(null).should.be.true()
      console.log.getCall(1).args.should.eql ['Executing', 'foo bar', 'on version', chalk.green('2.2.0')]
      console.log.getCall(3).args.should.eql ['Executing', 'foo bar', 'on version', chalk.green('4.0.0')]
      console.log.getCall(5).args.should.eql ['foo bar', 'completed successfully in node versions', '2.2.0 and 4.0.0']
