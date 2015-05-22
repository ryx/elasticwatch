log = require("loglevel")
Worker = require("./worker")
Validator = require("./validator")

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
    # create reporters
    for reporterName, cfg of @config.reporters
      log.debug("App.constructor: creating reporter #{reporterName}", cfg)
      reporter = @createReporter(reporterName, cfg)
      @reporters.push(reporter) if reporter
    # create a worker for each job
    if @config.jobs
      for jobName,i in @config.jobs
        # load config from file (@TODO: use OptionBuilder instead to use either commandline or file as config)
        try
          workerConfig = require("../#{jobName}")
        catch e
          if e.code is "MODULE_NOT_FOUND"
            log.error("ERROR: job module '#{jobName}' not found")
        # create worker from config
        worker = @createWorkerFromConfig(workerConfig)
        if worker
          worker.on("alarm", @handleAlarm)
          worker.start()
    else
      log.error("ERROR: no jobs defined")

  ###*
  # Instantiate Worker according to a given configuration.
  #
  # @method createWorker
  # @param  config  {Object} job configuration as read from JSON file
  ###
  createWorkerFromConfig: (jobCfg) ->
    log.debug(jobCfg)
     # @TODO: use dynamic validator classes somewhen
    validator = new Validator(jobCfg.fieldName, jobCfg.min, jobCfg.max, jobCfg.tolerance)
    # create Worker
    #try
    new Worker(
      jobCfg.name,
      jobCfg.elasticsearch.host,
      jobCfg.elasticsearch.port,
      "/#{jobCfg.elasticsearch.index}/#{jobCfg.elasticsearch.type}",
      jobCfg.query, # TODO: if we have a query use that, else build custom query using QueryBuilder
      validator
    )
    #catch e
    #  log.error("ERROR: worker creation failed: #{e.message}")
    #  null

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
      log.error("ERROR: failed to instantiate reporter: #{name}", e)
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
