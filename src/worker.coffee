log = require("loglevel")
http = require("http")
Reporter =require("./reporter")

###*
# The Worker does most of the magic. It takes a single test config, queries
# data from elasticsearch, analyzes the result, compares it to the expectation,
# raises an alarm and informs reporters where appropriate.
###
module.exports = class Worker

  ###*
  # Create a new Worker, prepare data, setup request options.
  # @constructor
  # @param  id  {String}  identifies this individual Worker instance
  # @param  config  {Object}  configuration object as supplied via Job config
  ###
  constructor: (@id, @config) ->
    if not @config
      throw new Error("no config supplied")
    # instantiate requested reporters
    @reporters = @createReporters(@config.reporters)

  ###*
  # Execute request and hand over control to onResponse callback.
  # @method start
  ###
  start: =>
    # build query data
    data = JSON.stringify({query:@config.query})
    # create post options
    @options =
      host: @config.elasticsearch.host
      port: @config.elasticsearch.port
      path: "/#{@config.elasticsearch.index}/#{@config.elasticsearch.type}/_search"
      method: "POST"
      headers:
        "Content-Type": "application/json"
        "Content-Length": Buffer.byteLength(data)
    # connect
    log.debug("Worker(#{@id}).start: connecting to elasticsearch at: #{@options.host}:#{@options.port}#{@options.path}")
    try
      @request = http.request(@options, @onResponse)
      @request.on("error", @onError)
      log.debug("Worker(#{@id}).start: query data is: ", data)
      @request.write(data)
      @request.end()
    catch e
      log.error("Worker(#{@id}).start: unhandled error: ", e.message)

  ###*
  # Instantiate reporters according to a given configuration.
  # @method createReporters
  # @param  configs  {Object} hash with configuration objects (key=reporter id, value=configuration)
  ###
  createReporters: (configs) =>
    reporters = []
    for name, cfg of configs
      log.debug("Worker(#{@id}).createReporters: creating reporter: #{name}")
      try
        r = require("./reporters/#{name}")
        reporters.push(new r(cfg))
      catch e
        log.error("Worker(#{@id}).createReporters: ERROR: failed to instantiate reporter: #{name}", e)
    reporters

  ###*
  # Gets passed ES response data (as object)
  # @method handleResponseData
  # @param  data  {Object}  result set as returned by ES
  ###
  handleResponseData: (data) ->
    # check number of results and raise error on empty query
    numHits = data.hits.total
    if numHits is 0
      @raiseAlarm("No results received")
      process.exitCode = 3
    log.debug("Worker(#{@id}).onResponse: query returned #{numHits} hits")
    # if expectations are not met, raise error
    if not @validateResult(data)
      @raiseAlarm("Alarm condition met")
      process.exit = 2

  ###
  # Test response and validate against expectation
  # @method validateResult
  # @param  data  {Object}
  ###
  validateResult: (data) =>
    if not data
      return false
    else
      consecutiveFails = 0
      for hit in data.hits.hits
        #log.debug(hit)
        val = hit._source[@config.fieldName]
        log.debug("Worker(#{@id}).validateResult: val #{val}")
        # value out of range?
        if (@config.max and val > @config.max) or (@config.min and val < @config.min)
          log.debug("Worker(#{@id}).validateResult: exceeds range")
          consecutiveFails++
        else
          consecutiveFails = 0
        # count number of fails
        if consecutiveFails > @config.tolerance
          return false
    true

  ###*
  # Raise alarm and notify all configured reporters.
  # @method raiseAlarm
  # @param  message {String}
  ###
  raiseAlarm: (message) =>
    # if they don't match: raise alarms and notify reporters
    for reporter in @reporters
      log.debug("Worker(#{@id}).raiseAlarm: notifiying reporter ", reporter)
      reporter.onAlarm(@config, message)

  ###*
  # http.request: success callback
  ###
  onResponse: (response) =>
    log.debug("Worker(#{@id}).onResponse: status is #{response.statusCode}")
    # if we have a success code
    if response.statusCode is 200
      body = ""
      response.setEncoding("utf8")
      response.on "data", (chunk) =>
        body += chunk
      response.on "end", (error) =>
        log.debug("Worker(#{@id}).onResponse: response was: ", body)
        # evaluate results and compare them to expectation
        try
          @handleResponseData(JSON.parse(body))
        catch e
          log.error("Worker(#{@id}).onResponse: failed to parse response data")
    else
      @request.end()
      process.exit(1)

  ###*
  # http.request: error callback
  ###
  onError: (error) =>
    if error.code is "ECONNREFUSED"
      log.error("ERROR: connection refused, please make sure elasticsearch is running and accessible under #{@options.host}:#{@options.port}")
    else
      log.debug("Worker(#{@id}).onError: unhandled error: ", error)
    @request.end()
