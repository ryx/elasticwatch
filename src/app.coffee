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
          (new Worker("#{i}", cfg)).start()
        catch e
          console.error(e)
          console.error("App.constructor: ERROR: test #{test} not found")
