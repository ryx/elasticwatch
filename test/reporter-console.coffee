# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[reporter] = []
loglevelMock =
  debug: (str) ->
    @strDebug = str
  error: (str) ->
    @strError = str

# setup mockery
mockery.enable({
  useCleanCache: true
})
mockery.registerMock("loglevel", loglevelMock)
mockery.registerAllowables([
  "../src/reporters/console"
  "../reporter"
])

# load module to be tested
ConsoleReporter = require("../src/reporters/console")

# setup test
describe "ConsoleReporter", ->

  beforeEach ->
    reporter = new ConsoleReporter()

  it "should output a log message during construction", ->
    assert.include(loglevelMock.strDebug, "creating new instance")

  it "should log an error when notify is called", ->
    reporter.notify("mymessage", {name:"myname"})
    assert.include(loglevelMock.strError, "'myname' raised alarm: mymessage")
