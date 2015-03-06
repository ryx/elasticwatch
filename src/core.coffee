http = require("http")

###*
# The main application logic and entry point. Reads args, sets things up,
# runs workers.
###
class App

  constructor: ->
    # read args and setup core options
    # An object of options to indicate where to post to
    # ...
    # read configs
    # ...
    # perform requests based on configs
    new Worker()
    # -> loop (done in worker):
    # ... instantiate required reporters
    # ... perform request
    # ... raise alarms
    # ... notify reporters


###*
# The worker does most of the magic. It takes a single config, connects
# to elasticsearch, analyzes the result, compares it to the expectation
# and raises an alarm where appropriate.
###
class Worker

  constructor: (@config) ->
    # ElasticSearch Expects JSON not Querystring!
    data = JSON.stringify({
      "text" :"everything is awesome"
    })
    # create post options (@TODO: use info from config)
    @options =
      host: "localhost"
      port: "8000"
      path: "/"
      method: "POST"
      headers:
        "Content-Type": "application/json"
        "Content-Length": Buffer.byteLength(data)
    try
      @request = http.request(@options, @callback)
    catch e
      console.log(e.message)
    if @request
      @request.write(data)
      @request.end()

  # server callback
  callback: (response) =>
    if not response
      throw new Error("response failed")
    # if we have a success code
    if response.statusCode is 200
      str = ""
      console.log("Status OK")
      response.setEncoding("utf8")
      response.on "data", (chunk) ->
        str += chunk
        console.log("Chunk: " + chunk)
      response.on "end", (error) ->
        console.log("Response: " + str)
    else
      @request.end()

# create module exports
module.exports =
  App: App
  Worker: Worker
