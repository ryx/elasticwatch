log = require("loglevel")
http = require("http")
Worker = require("./worker")

###*
# The main application logic and entry point. Reads args, sets things up,
# runs workers.
###
module.exports = class App

  constructor: (@config) ->
    # run over tests and create worker for each test
    if @config.tests
      for test, i in @config.tests
        # perform requests based on configs
        try
          cfg = require("../tests/#{test}")
          (new Worker("#{i}", @config.host, @config.port, cfg)).start()
        catch e
          if e.code is "MODULE_NOT_FOUND"
            log.error("App.constructor: ERROR: test module '#{test}' not found")
          else
            log.error("App.constructor: ERROR: unhandled error", e)
