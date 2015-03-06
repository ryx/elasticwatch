http = require("http")
Worker = require("./worker")

###*
# The main application logic and entry point. Reads args, sets things up,
# runs workers.
###
module.exports = class App

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
