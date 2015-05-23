# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[app, configMock] = []
loglevelMock =
  debug: (str) ->
    console.log(str)
    @strDebug = str
  error: (str) ->
    console.error(str)
    @strError = str
#httpMock =
#  request: () ->
configMock =
  jobs: ["jobs/example.json"]
  reporters:
    console: {}

# setup mockery
mockery.enable({
  useCleanCache: true
})
mockery.registerMock("loglevel", loglevelMock)
#mockery.registerMock("http", httpMock)
mockery.registerAllowables([
  "../reporter",
  "../src/reporter",
  "./reporters/console",
  "../src/reporters/console",
  "../worker",
  "../src/worker"
])

# load module to be tested
App = require("../src/app")
ConsoleReporter = require("../src/reporters/console")
Worker = require("../src/worker")

describe "App", ->

  beforeEach ->
    app = new App(configMock)

  describe "createWorkerFromConfig", ->

    it "should create a Worker from a given config", ->
      workerConfig =
        name: "testworker"
        elasticsearch:
          host:"localhost"
          port:9200
          index:"_all"
          type:"type"
        query:{}
        fieldName: "prop"
        min: 10
        max: 30
        tolerance: 5
      assert.instanceOf(app.createWorkerFromConfig(workerConfig), Worker)

    it "should return null if the Worker can't be created", ->
      assert.isNull(app.createWorkerFromConfig())

  describe "createReporter", ->

    it "should create the correct Reporter (ConsoleReporter) from a given config", ->
      assert.instanceOf(app.createReporter("console", {}), ConsoleReporter)

    it "should return null if the reporter can't be created", ->
      assert.isNull(app.createReporter("!_random_garbage_!", {}))
