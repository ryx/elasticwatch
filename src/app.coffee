log = require("loglevel")
http = require("http")
Worker = require("./worker")

###*
# The main application logic and entry point. Reads args, sets things up,
# runs workers.
#
# @class  App
###
module.exports = class App

  ###*
  # Create a new App based on the given configuration.
  #
  # @constructor
  ###
  constructor: (@config) ->
    @reporters = []
    log.debug("App.constructor: creating app", @config)
    # create Reporter instances
    for name, cfg of @config.reporters
      log.debug("App.constructor: creating reporter #{name}", cfg)
      reporter = @createReporter(name, cfg)
      @reporters.push(reporter) if reporter
    # create a worker for each job
    if @config.jobs
      for name, i in @config.jobs
        # create Worker based on configuration
        worker = @createWorker(name)
        if not worker
          log.error("App.constructor: ERROR: failed to create job #{name}")
        else
          worker.on("alarm", @handleAlarm)
          worker.start()
    else
      log.error("App.constructor: ERROR: no jobs defined")

  ###*
  # Instantiate Worker according to a given configuration.
  #
  # @method createWorker
  # @param  config  {Object} hash with configuration objects (key=reporter id, value=configuration)
  ###
  createWorker: (jobName) ->
    try
      cfg = require("../#{jobName}")
      new Worker(jobName, cfg)
    catch e
      if e.code is "MODULE_NOT_FOUND"
        log.error("App.constructor: ERROR: job module '#{jobName}' not found")
      else
        log.error("App.constructor: ERROR: unhandled error", e)
      null

  ###*
  # Instantiate a Reporter according to a given configuration.
  #
  # @method createReporter
  # @param  name    {String} module name of reporter to create
  # @param  config  {Object} hash with reporter configuration object
  ###
  createReporter: (name, config) ->
    log.debug("App.createReporter: creating reporter: #{name} ", config)
    try
      r = require("./reporters/#{name}")
      new r(config)
    catch e
      log.error("App.createReporters: ERROR: failed to instantiate reporter: #{name}", e)
      null

  ###*
  # Handle alarm event sent by a worker. Notifies all exitsing reporters about
  # a given event.
  #
  # @method handleAlarm
  # @param  event {Object}  the event object passed to alarm event
  ###
  handleAlarm: (message, data) =>
    log.debug("App.handleAlarm: #{message}", data)
    for reporter,i in @reporters
      reporter.notify(message, data)
