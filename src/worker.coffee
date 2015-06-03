log = require("loglevel")
http = require("http")
events = require("events")

###*
# The Worker does most of the magic. It connects to elasticsearch, queries
# data, analyzes the result, compares it to the expectation and raises an alarm
# when appropriate.
#
# @class    Worker
# @extends  events.EventEmitter
###
module.exports = class Worker extends events.EventEmitter

  # result codes (maps to process exit codes)
  @ResultCodes:
    Success:
      code: 0
      label: "SUCCESS"
    ValidationFailed:
      code: 1
      label: "ALARM_VALIDATION_FAILED"
    NoResults:
      code: 2
      label: "ALARM_NO_RESULTS_RECEIVED"
    NotFound:
      code: 4
      label: "ALARM_NOT_FOUND_404"
    InvalidResponse:
      code: 5
      label: "ALARM_INVALID_RESPONSE"
    ConnectionRefused:
      code: 6
      label: "ALARM_CONNECTION_REFUSED"
    UnhandledError:
      code: 99
      label: "ALARM_UNHANDLED_ERROR"

  ###*
  # Create a new Worker, prepare data, setup request options.
  #
  # @constructor
  # @param  id        {String}  identifies this individual Worker instance
  # @param  host      {String}  elasticsearch hostname to connect to
  # @param  port      {String}  elasticsearch port to connect to
  # @param  path      {String}  elasticsearch path (in form /{index}/{type})
  # @param  query     {Object}  valid elasticsearch query
  # @param  validator {ResultValidator} a validator object that takes the response and compares it against a given expectation
  ###
  constructor: (@id, @host, @port, @path, @query, @validator) ->
    if not @id or not @host or not @port or not @path or not @query or not @validator
      throw new Error("Worker.constructor: invalid number of options received: #{JSON.stringify(arguments)}")

  ###*
  # Execute request and hand over control to onResponse callback.
  #
  # @method start
  ###
  start: =>
    # build query data
    data = JSON.stringify({query:@query})
    # create post options
    @options =
      host: @host
      port: @port
      path: "#{@path}/_search"
      method: "POST"
      headers:
        "Content-Type": "application/json"
        "Content-Length": Buffer.byteLength(data)
    # connect
    log.debug("Worker(#{@id}).sendESRequest: connecting to elasticsearch at: #{@host}:#{@port}#{@path}")
    try
      @request = http.request(@options, @onResponse)
      @request.on("error", @onError)
      log.debug("Worker(#{@id}).sendESRequest: query data is: ", data)
      @request.write(data)
      @request.end()
      return true
    catch e
      log.error("Worker(#{@id}).start: unhandled error: #{e.message}")

  ###*
  # Gets passed ES response data (as object) and pre-validates the contents.
  # If data is invalid or result is empty an error is raised. Valid results
  # are handed over to the ResultValidator for further analysis. If any alarm
  # condition is met, raiseAlarm is called with the appropriate alarm.
  #
  # @method handleResponseData
  # @param  data  {Object}  result set as returned by ES
  ###
  handleResponseData: (data) ->
    result = null
    rc = Worker.ResultCodes
    # validate response data
    if not data or typeof data.hits is "undefined"
      result = rc.InvalidResponse
    else
      # check number of results and raise error on empty queries
      numHits = data.hits.total
      log.debug("Worker(#{@id}).onResponse: query returned #{numHits} hits")
      if numHits is 0
        result = rc.NoResults
      else if not @validator.validate(data)
        # if expectations are not met, raise error
        result = rc.ValidationFailed
      else
        result = rc.Success
    # perform action
    if result is rc.Success
      return true
    else
      @raiseAlarm("#{result.label}: #{@validator.getMessage()}")
      process.exitCode = result.code
      return false

  ###*
  # Raise alarm - emits "alarm" event that can be handled by interested
  # listeners.
  #
  # @method raiseAlarm
  # @emits  alarm
  # @param  message {String}  error message
  # @param  data    {object}  any additional data
  ###
  raiseAlarm: (message) =>
    log.debug("Worker(#{@id}).raiseAlarm: raising alarm: #{message}")
    @emit("alarm", message, {name:@id})

  ###*
  # http.request: success callback
  #
  # @method onResponse
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
          data = JSON.parse(body)
        catch e
          log.error("Worker(#{@id}).onResponse: failed to parse response data")
        if data
          @handleResponseData(data)
    else
      @raiseAlarm("#{Worker.ResultCodes.NotFound.label}")
      process.exitCode = Worker.ResultCodes.NotFound.code
      @request.end()
      process.exit()

  ###*
  # http.request: error callback
  #
  # @method onError
  ###
  onError: (error) =>
    if error.code is "ECONNREFUSED"
      log.error("ERROR: connection refused, please make sure elasticsearch is running and accessible under #{@options.host}:#{@options.port}")
      @raiseAlarm("#{Worker.ResultCodes.ConnectionRefused.label}")
      process.exitCode = Worker.ResultCodes.ConnectionRefused.code
    else
      log.debug("Worker(#{@id}).onError: unhandled error: ", error)
      @raiseAlarm("#{Worker.ResultCodes.UnhandledError.label}: #{error}")
      process.exitCode = Worker.ResultCodes.UnhandledError.code
    @request.end()
