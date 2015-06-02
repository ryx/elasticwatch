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
  # @param  config  {Object}  object with configuration options (name, elasticsearch, query, reporter(s) and validator)
  ###
  constructor: (@config) ->
    log.debug("App.constructor: creating app", @config)
    # validate config
    for s in ["name","elasticsearch","query","reporters","validator"]
      if not @config[s]
        throw new Error("App.constructor: config.#{s} missing")
    # create reporters
    @reporters = []
    for reporterName, cfg of @config.reporters
      log.debug("App.constructor: creating reporter '#{reporterName}'")
      reporter = App.createReporter(reporterName, cfg)
      @reporters.push(reporter) if reporter
    # create validator
    # @TODO: add support for multiple types and pass it in as {"typename":{...}}
    @validator = App.createValidator("validator", @config.validator)
    # create worker
    log.debug("App.constructor: creating worker")
    @worker = App.createWorker(@config.name, @config.elasticsearch, @config.query, @validator)
    if @worker
      @worker.on("alarm", @handleAlarm)
      @worker.start()
    else
      throw new Error("App.constructor: worker creation failed")

  ###*
  # Instantiate Worker according to a given configuration.
  #
  # @method createWorker
  # @static
  # @param  name                  {String}    worker name/id
  # @param  elasticsearchConfig   {Object}    elasticsearch config (host/port/index/type)
  # @param  query                 {Object}    elasticsearch query object
  # @param  validator             {Validator} validator object to be passed to Worker
  ###
  @createWorker: (name, elasticsearchConfig, query, validator) ->
    if not name or not elasticsearchConfig or not query or not validator
      log.error("App.createWorker: invalid number of options")
      return null
    # create Worker
    try
      new Worker(
        name,
        elasticsearchConfig.host,
        elasticsearchConfig.port,
        "/#{elasticsearchConfig.index}/#{elasticsearchConfig.type}",
        query, # TODO: if we have a query use that, else build custom query using QueryBuilder
        validator
      )
    catch e
      log.error("ERROR: worker creation failed: #{e.message}")
      null

  ###*
  # Instantiate a Reporter according to a given configuration.
  #
  # @method createReporter
  # @static
  # @param  name    {String} module name of reporter to create
  # @param  config  {Object} hash with reporter configuration object
  ###
  @createReporter: (name, config) ->
    log.debug("App.createReporter: creating reporter: #{name} ", config)
    try
      r = require("./reporters/#{name}")
      o = new (r)(config)
      return o
    catch e
      log.error("ERROR: failed to instantiate reporter '#{name}': #{e.message}", r)
      null

  ###*
  # Instantiate a Validator according to a given configuration.
  # @FIXME: currently there is only one validator but in the future there will be more different types
  #
  # @method createValidator
  # @static
  # @param  name    {String} module name of validator to create
  # @param  config  {Object} hash with validator configuration object
  ###
  @createValidator: (name, config) ->
    log.debug("App.createValidator: creating validator: #{name} ", config)
    try
      # @FIXME temp! should pass config object here
      o = new Validator(config.fieldName, config.min, config.max, config.tolerance)
      return o
    catch e
      log.error("ERROR: failed to instantiate validator '#{name}': #{e.message}", o)
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
