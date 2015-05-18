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
  request: (opts, callback) ->

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
ConsoleReporter = require("../src/reporters/console")

describe "Worker", ->

  describe "constructor", ->

    it "should have the assigned id", ->
      assert.equal(new Worker("testworker", {}).id, "testworker", "id property should equal the constructor's first argument")

    it "should break on empty config", ->
      init = ->
        new Worker("testworker")
      assert.throw(init, Error, "no config supplied", "constructor should get a config object as second argument")

    it "should instantiate reporter(s) if config.reporters is set", ->
      worker = new Worker("testworker", {reporters:{"console":{}}})
      assert.isArray(worker.reporters, "@reporters should be an Array")

  describe "start", ->

    beforeEach ->
      worker = new Worker("testworker", {})

    #it "should create a correct query string", ->
    #  worker = new Worker("testworker", {})
    #  func = ->
    #    worker.start()
    #  assert.throw(func, Error, "failed to parse query")

    #it "should break on invalid query data", ->

  describe "sendESRequest", ->

    beforeEach ->
      worker = new Worker("testworker", {})

    it "should break if any parameter is missing or null", ->
      assert.isFalse(worker.sendESRequest(null, 9200, "/index/type", {foo:"bar"}))
      assert.isFalse(worker.sendESRequest("myhost", null, "/index/type", {foo:"bar"}))
      assert.isFalse(worker.sendESRequest("myhost", 9200, null, {foo:"bar"}))
      assert.isFalse(worker.sendESRequest("myhost", 9200, "/index/type", null))

    it "should send a successful request if all data is available", ->
      worker.sendESRequest("myhost", "9200", "/index/type", {foo:"bar"})

  describe "reporters", ->

    beforeEach ->
      worker = new Worker("testworker", {})

    it "createReporters should take a hash with configs and return an array with Reporter objects", ->
      reporters = worker.createReporters({console:{}})
      assert.instanceOf(reporters[0], ConsoleReporter, "first entry in reporters list should be a ConsoleReporter")
