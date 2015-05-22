# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[app, configMock] = []
loglevelMock =
  strDebug: ""
  strError: ""
  debug: (str) ->
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
#mockery.registerAllowables([
#  "../reporter"
#])

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
          path:"/_all"
        query:""
      assert.instanceOf(app.createWorkerFromConfig(workerConfig), Worker)

    it "should return null if the reporter can't be created", ->
      assert.isNull(app.createWorkerFromConfig())

  describe "createReporter", ->

    it "should create the correct reporter (ConsoleReporter) from a given config", ->
      assert.instanceOf(app.createReporter("console", {}), ConsoleReporter, "object should be of type ConsoleReporter")

    it "should return null if the reporter can't be created", ->
      assert.isNull(app.createReporter("!_random_garbage_!", {}))
