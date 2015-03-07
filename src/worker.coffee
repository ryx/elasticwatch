http = require("http")
Reporter =require("./reporter")

###*
# The Worker does most of the magic. It takes a single test config, queries
# data from elasticsearch, analyzes the result, compares it to the expectation,
# raises an alarm and informs reporters where appropriate.
###
module.exports = class Worker

  # prepare data, setup request options
  constructor: (@id, @config) ->
    # @FIXME: validate config
    # ...
    # instantiate requested reporters
    @reporters = []
    for name, cfg of @config.reporters
      console.log("Worker(#{@id}).constructor: creating reporter: #{name}", cfg)
      try
        r = require("./reporters/#{name}")
        @reporters.push(new r(cfg))
      catch e
        console.error("Worker(#{@id}).constructor: ERROR: failed to instantiate reporter #{name}", e)
    # build query data
    @data = JSON.stringify({query:@config.query})
    # create post options
    @options =
      host: "localhost" # @FIXME use global config here
      port: "9200" # @FIXME use global config here
      path: "/#{@config.index}/#{@config.type}/_search"
      method: "POST"
      headers:
        "Content-Type": "application/json"
        "Content-Length": Buffer.byteLength(@data)

  # start working (executes request and hands over control to onResponse callback)
  start: =>
    try
      @request = http.request(@options, @onResponse)
      @request.on("error", @onError)
      console.log("Worker(#{@id}).start: query data is: ", @data)
      @request.write(@data)
      @request.end()
    catch e
      console.error("Worker(#{@id}).start: unhandled error: ", e.message)

  # success callback
  onResponse: (response) =>
    console.log("Worker(#{@id}).onResponse: status is #{response.statusCode}")
    # if we have a success code
    if response.statusCode is 200
      body = ""
      response.setEncoding("utf8")
      response.on "data", (chunk) =>
        body += chunk
      response.on "end", (error) =>
        console.log("Worker(#{@id}).onResponse: response was: ", body)
        # evaluate results and compare them to expectation
        # @TODO ...
        # if they don't match: raise alarms and notify reporters
        if 1
          for reporter in @reporters
            console.log("Worker(#{@id}).onResponse: notifiying reporter ", reporter)
            reporter.onAlarm(@, "Alarm condition met")
    else
      @request.end()

  # error handling callback
  onError: (error) =>
    if error.code is "ECONNREFUSED"
      console.error("ERROR: connection refused, please make sure elasticsearch is running and accessible under #{@options.host}:#{@options.port}")
    else
      console.log("Worker(#{@id}).onError: unhandled error: ", error)
    @request.end()
