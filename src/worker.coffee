http = require("http")

###*
# The worker does most of the magic. It takes a single config, connects
# to elasticsearch, analyzes the result, compares it to the expectation
# and raises an alarm where appropriate.
###
module.exports = class Worker

  constructor: (@config) ->
    # ElasticSearch Expects JSON not Querystring!
    data = JSON.stringify({
      query:
        query_string:
          query: "_exists_:NavTimingRenderTime"
          analyze_wildcard: true
    })
    console.log("POST data is: ", data)
    # create post options (@TODO: use info from config)
    @options =
      host: "localhost"
      port: "9200"
      path: "/logstash-2015.02.21/jsonlog/_search"  # @TODO use index/type from config here
      method: "POST"
      headers:
        "Content-Type": "application/json"
        "Content-Length": Buffer.byteLength(data)
    try
      @request = http.request(@options, @onResponse)
      @request.on("error", @onError)
    catch e
      console.log(e.message)
    if @request
      @request.write(data)
      @request.end()

  # success callback
  onResponse: (response) =>
    #console.log("onResponse: ", response)
    # if we have a success code
    if response.statusCode is 200
      body = ""
      console.log("Status OK")
      response.setEncoding("utf8")

      response.on "data", (chunk) ->
        body += chunk
        console.log("Chunk: " + chunk)

      response.on "end", (error) ->
        console.log("Response: " + body)
    else
      console.log("Status is ", response.statusCode)
      @request.end()

  # error handling callback
  onError: (error) =>
    if error.code is "ECONNREFUSED"
      console.error("ERROR: connection refused, please make sure elasticsearch is running and accessible under #{@options.host}:#{@options.port}")
    else
      console.log("ERROR: unhandled", error)
    @request.end()
