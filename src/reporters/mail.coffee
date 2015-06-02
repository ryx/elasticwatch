log = require("loglevel")
exec = require('child_process').exec
Reporter = require("../reporter")

###*
# A Reporter that sends an e-mail to a given address, using the system's mail
# commandline client.
#
# @class    MailReporter
# @extends  Reporter
###
module.exports = class MailReporter extends Reporter

  constructor: (@config={}) ->
    @maxRetries = @config.maxRetries or 3
    @retryAttempt = 0
    log.debug("MailReporter.constructor: creating new instance", @config)
    if not @config.targetAddress
      log.error("ERROR: mail reporter requires 'targetAddress' in configuration")

  ###*
  # Send a mail (using the system's "mail" commandline tool).
  #
  # @method sendMail
  # @param  target      {String}    e-mail address (or comma-separated list of addresses) to send mail to
  # @param  subject     {String}    mail subject
  # @param  body        {String}    message body
  # @param  onSuccess   {Function}  success callback
  # @param  onError     {Function}  error callback
  ###
  sendMail: (target, subject, body, onSuccess=(->), onError=(->)) ->
    child = exec "echo \"#{body}\" | mail -s \"#{subject}\" #{target}", (error, stdout, stderr) ->
      if error isnt null then onError(error) else onSuccess()

  ###*
  # Send notification to this reporter.
  ###
  notify: (message, data) ->
    log.debug("MailReporter.notify: '#{data.name}' raised alarm: #{message}")
    @sendMail(
      @config.targetAddress,
      "[elasticwatch] #{data.name} raised alarm",
      "Hi buddy, \n\nalarm message was: #{message}\n\nCheers,\nyour elasticwatch",
      () ->,
      (error) =>
        # output notification on error and retry mail delivery
        log.error("ERROR: mail delivery failed: #{error}")
        if @retryAttempt < @maxRetries
          @retryAttempt++
          @notfiy(message, data)
        else
          log.error("ERROR: mail delivery failed #{@maxRetries} times")
          @retryAttempt = 0
    )
