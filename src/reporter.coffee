###*
# The Reporter is an abstract base class that takes information from a
# Worker and can do anything with that data. Actual implementations might
# do things as e.g. send an email or create a ticket.
###
module.exports = class Reporter

  # Create new Reporter with the given configuration object
  constructor: (@config) ->

  # notify the reporter about an alarm
  onAlarm: (test, message) ->
