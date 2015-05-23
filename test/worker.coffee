# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[worker] = []

# mock "loglevel"
loglevelMock =
  debug: (str) ->
    @strDebug = str
  error: (str) ->
    @strError = str
    #console.error(str)  # so we see errors in console output

# mock "http"
httpMock =
  request: (options) ->
    @requestOptions = options
    {
      on: ->
      end: ->
      write: (data) =>
        httpMock.writeData = data
    }

# mock "validator"
validatorMock =
  validate: (data) ->
    true

# setup mockery
mockery.enable({
  useCleanCache: true
})
mockery.registerMock("loglevel", loglevelMock)
mockery.registerMock("http", httpMock)
mockery.registerMock("./validator", validatorMock)
mockery.registerAllowables(["../src/worker", "events"])

# load module to be tested
Worker = require("../src/worker")

describe "Worker", ->

  describe "constructor", ->

    it "should have the assigned id", ->
      assert.equal(new Worker("testworker", "host", 9200, "/_all", {}, validatorMock).id, "testworker", "id property should equal the constructor's first argument")

    it "should break if any argument of [id,host,port,path,query] is missing", ->
      assert.throw((->new Worker(null, "host", 9200, "/_all", {}, validatorMock)), Error, "invalid number of options")
      assert.throw((->new Worker("testworker", null, 9200, "/_all", {}, validatorMock)), Error, "invalid number of options")
      assert.throw((->new Worker("testworker", "host", null, "/_all", {}, validatorMock)), Error, "invalid number of options")
      assert.throw((->new Worker("testworker", "host", 9200, null, {}, validatorMock)), Error, "invalid number of options")
      assert.throw((->new Worker("testworker", "host", 9200, "/_all", null, validatorMock)), Error, "invalid number of options")
      assert.throw((->new Worker("testworker", "host", 9200, "/_all", {}, null)), Error, "invalid number of options")

  describe "start", ->

    it "should establish an http connection using the supplied options", ->
      new Worker("testworker", "testhost", 9200, "/_all", {foo:"bar"}, validatorMock).start()
      assert.equal(httpMock.requestOptions.host, "testhost")
      assert.equal(httpMock.requestOptions.port, 9200)
      assert.equal(httpMock.requestOptions.path, "/_all/_search")

    it "should send the stringified query through http", ->
      queryMock = {foo:"bar"}
      new Worker("testworker", "testhost", 9200, "/_all", queryMock, validatorMock).start()
      assert.equal(httpMock.writeData, JSON.stringify({query:queryMock}))

  ###
  data = '{"foo":"bar"}'
  responseMock =
    statusCode: 200
    on: (name, callback) ->
      if name is "data"
        callback(data)
      else if name is "end"
        callback()
  assert.equal(true, false)
  ###

  describe "handleResponseData", ->
    [worker, resultStub] = []

    beforeEach ->
      worker = new Worker("testworker", "testhost", 9200, "/_all", {foo:"bar"}, validatorMock)
      resultStub =
        hits:
          total: 1
          hits: [
            {_source:{prop:1}}
          ]

    it "should emit an 'alarm' event when data validation fails due to invalid data", (done) ->
      worker.on "alarm", (msg) ->
        assert.include(msg, "Invalid data received")
        done()
      worker.handleResponseData({})

    it "should emit an 'alarm' event when handleResponseData didn't receive any results", (done) ->
      worker.on "alarm", (msg) ->
        assert.include(msg, "No results received")
        done()
      worker.handleResponseData({hits:{total:0,hits:[]}})

    it "should emit an 'alarm' event when data validation fails", (done) ->
      validatorMock.validate = (->false)
      worker.on "alarm", (msg) ->
        assert.include(msg, "Alarm condition met")
        done()
      worker.handleResponseData(resultStub)

    it "should simply return true if data validation succeeds", ->
      validatorMock.validate = (->true)
      assert.isTrue(worker.handleResponseData(resultStub))
