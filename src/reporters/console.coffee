log = require("loglevel")
Reporter = require("../reporter")

###*
# A Reporter that logs an error message to the console. As simple as possible,
# but should illustrate the basic idea of what a reporter is all about.
###
module.exports = class ConsoleReporter extends Reporter

  constructor: (@config) ->
    log.debug("ConsoleReporter.constructor: creating new instance", @config)
    @prefix = @config?.prefix or "ConsoleReporter.onAlarm"

  onAlarm: (test, message) ->
    log.error("#{@prefix}: Test with name #{test.name} failed with alarm: #{message}")
