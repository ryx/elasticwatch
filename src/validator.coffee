log = require("loglevel")

###*
# The Validator takes an elasticsearch query result and compares it to a
# defined expectation (default is "value is within range of min/max for n
# times").
#
# @class   Validator
###
module.exports = class Validator

  ###*
  # Create a new Validator with the given options.
  # @constructor
  # @param  fieldName {String}  name of the result field (key) to use as comaprison value
  # @param  min       {int}     minimum allowed value (= lower bound)
  # @param  max       {int}     maximum allowed value (= upper bound)
  # @param  tolerance {int}     maximum allowed number of consecutive values that do not match the expectation
  ###
  constructor: (@fieldName, @min, @max, @tolerance) ->
    if not @fieldName or @min is null or @max is null or @tolerance is null
      throw new Error("invalid number of options")

  ###
  # Validate the given elasticsearch query result against the expectation.
  #
  # @method validate
  # @param  data  {Object}  elasticsearch query result
  ###
  validate: (data) =>
    if not data
      return false
    else
      consecutiveFails = 0
      for hit in data.hits.hits
        #log.debug(hit)
        val = hit._source[@fieldName]
        log.debug("Validator.validate: val #{val}")
        # value out of range?
        if (@max and val > @max) or (@min and val < @min)
          log.debug("Validator.validate: exceeds range")
          consecutiveFails++
        else
          consecutiveFails = 0
        # count number of fails
        if consecutiveFails > @tolerance
          log.debug("Validator.validate: more than #{@tolerance} consecutive fails occured")
          return false
    true
