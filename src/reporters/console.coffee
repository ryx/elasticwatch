log = require("loglevel")
Reporter = require("../reporter")

###*
# A Reporter that logs an error message to the console. As simple as possible,
# but should illustrate the basic idea of what a reporter is all about.
#
# @class    ConsoleReporter
# @extends  Reporter
###
module.exports = class ConsoleReporter extends Reporter

  constructor: (@config) ->
    log.debug("ConsoleReporter.constructor: creating new instance", @config)

  notify: (message, data) ->
    log.error("ConsoleReporter.notify: '#{data.name}' raised alarm: #{message}")
