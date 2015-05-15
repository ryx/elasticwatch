# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[worker] = []
loglevelMock =
  strDebug: ""
  strError: ""
  debug: (str) ->
    @strDebug = str
  error: (str) ->
    @strError = str
httpMock =
  request: () ->

# setup mockery
mockery.enable({
  useCleanCache: true
})
mockery.registerMock("loglevel", loglevelMock)
mockery.registerMock("http", httpMock)
#mockery.registerAllowables([
#  "../reporter"
#])

# load module to be tested
Worker = require("../src/worker")

describe "Worker", ->

  describe "constructor", ->

    beforeEach ->
      worker = new Worker("testworker", {})

    it "should break on empty config", ->
      init = ->
        new Worker("testworker", {})
      assert.throw(init, Error, "bloo")

  describe "reporters", ->

    it "should instantiate a reporter if config.reporters is set", ->
      worker = new Worker("testworker", {reporters:{"console":{}}})
      assert.notNull(worker.reporters)
      assert.true(worker.reporters[0].instanceof ConsoleReporter)
