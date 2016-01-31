fs = require 'fs'

describe 'n-run', ->
  afterEach (done) -> fs.unlink "#{__dirname}/output.txt", (err) -> done()
  Given -> @subject = require '../../lib/n-run'
  When (done) -> @subject.run "#{__dirname}/test.js", ['0.10', '0.12', '1', '2', '3', '4', '5'], done
  And (done) -> fs.readFile "#{__dirname}/output.txt", { encoding: 'utf8' }, (err, file) =>
    if (err)
      console.log('an error occurred:', err)
      done(err)
    else
      @file = file.split('\n')
      done()
  Then ->
    /v0\.10\.\d+/.test(@file[0]).should.be.true()
    /v0\.12\.\d+/.test(@file[1]).should.be.true()
    /v1\.\d+\.\d+/.test(@file[2]).should.be.true()
    /v2\.\d+\.\d+/.test(@file[3]).should.be.true()
    /v3\.\d+\.\d+/.test(@file[4]).should.be.true()
    /v4\.\d+\.\d+/.test(@file[5]).should.be.true()
    /v5\.\d+\.\d+/.test(@file[6]).should.be.true()

