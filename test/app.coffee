# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[app, configMock] = []
loglevelMock =
  debug: (str) ->
    #console.log(str)
    @strDebug = str
  error: (str) ->
    console.error(str)
    @strError = str

# App example configuration
configMock =
  name: "Test"
  elasticsearch:
    host:"localhost"
    port:9200
    index:"_all"
    type:"type"
  query: {}
  reporters:
    console: {}
  validator:
    fieldName: "prop"
    min: 10
    max: 30
    tolerance: 5

# setup mockery
mockery.registerMock("loglevel", loglevelMock)
mockery.registerAllowables([
  "../reporter"
  "../src/reporter"
  "./reporters/console"
  "../src/reporters/console"
  "../worker"
  "../src/worker"
])
mockery.enable({
  useCleanCache: true
})

# load module to be tested
App = require("../src/app")
ConsoleReporter = require("../src/reporters/console")
Worker = require("../src/worker")
Validator = require("../src/validator")

describe "App", ->

  describe "init", ->
    [stub] = []

    beforeEach ->
      stub =
        name: 1
        elasticsearch: 1
        query: 1
        reporters: 1
        validator: 1

    it "should throw an error if config.name is missing", ->
      delete stub.name
      init = ->
        new App(stub)
      assert.throw(init, Error, "config.name missing")

    it "should throw an error if config.elasticsearch is missing", ->
      delete stub.elasticsearch
      init = ->
        new App(stub)
      assert.throw(init, Error, "config.elasticsearch missing")

    it "should throw an error if config.query is missing", ->
      delete stub.query
      init = ->
        new App(stub)
      assert.throw(init, Error, "config.query missing")

    it "should throw an error if config.reporters is missing", ->
      delete stub.reporters
      init = ->
        new App(stub)
      assert.throw(init, Error, "config.reporters missing")

    it "should throw an error if config.validator is missing", ->
      delete stub.validator
      init = ->
        new App(stub)
      assert.throw(init, Error, "config.validator missing")

  describe "App.createWorker", ->

    it "should create a Worker from a given config", ->
      assert.instanceOf(App.createWorker("testworker", configMock.elasticsearch, configMock.query, {}), Worker)

    it "should return null if any of the options are missing", ->
      assert.isNull(App.createWorker(null,  {}, {}, {}))
      assert.isNull(App.createWorker("name", null, {}, {}))
      assert.isNull(App.createWorker("name", {}, null, {}))
      assert.isNull(App.createWorker("name", {}, {}, null))

    it "should return null if the Worker can't be created", ->
      assert.isNull(App.createWorker())

  describe "App.createValidator", ->

    it "should create a Validator from a given config", ->
      assert.instanceOf(App.createValidator("validator", configMock.validator), Validator)

    it "should return null if the validator can't be created", ->
      assert.isNull(App.createValidator("!_random_garbage_!", {}))

  describe "App.createReporter", ->

    it "should create the correct Reporter (ConsoleReporter) from a given config", ->
      assert.instanceOf(App.createReporter("console", {}), ConsoleReporter)

    it "should return null if the reporter can't be created", ->
      assert.isNull(App.createReporter("!_random_garbage_!", {}))
