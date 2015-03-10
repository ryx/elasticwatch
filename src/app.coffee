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
    if @config.jobs
      for job, i in @config.jobs
        # perform requests based on configs
        try
          cfg = require("../#{job}")
          (new Worker("#{i}", cfg)).start()
        catch e
          if e.code is "MODULE_NOT_FOUND"
            log.error("App.constructor: ERROR: job module '#{job}' not found")
          else
            log.error("App.constructor: ERROR: unhandled error", e)
    else
      log.error("App.constructor: ERROR: no jobs defined")
