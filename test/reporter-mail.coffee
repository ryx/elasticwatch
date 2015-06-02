# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[reporter] = []

loglevelMock =
  debug: (str) ->
    @strDebug = str
  error: (str) ->
    @strError = str
childProcessMock =
  mailCommand: ""
  exec: (command, callback) =>
    childProcessMock.mailCommand = command
    callback(null)

# setup mockery
mockery.enable({
  useCleanCache: true
})
mockery.registerMock("loglevel", loglevelMock)
mockery.registerMock("child_process", childProcessMock)
mockery.registerAllowables([
  "../src/reporters/console"
  "../reporter"
])

# load module to be tested
MailReporter = require("../src/reporters/mail")

# setup test
describe "MailReporter", ->

  describe "init", ->

    it "should output a log message during construction", ->
      new MailReporter()
      assert.include(loglevelMock.strDebug, "creating new instance")

    it "should throw an error if no target address is supplied", ->
      new MailReporter()
      assert.include(loglevelMock.strError, "requires 'targetAddress'")

    it "should set maxRetries to the supplied value [10]", ->
      reporter = new MailReporter({maxRetries:10})
      assert.equal(reporter.maxRetries, 10)

    it "should set maxRetries to 3 if only an e-mail address is defined", ->
      reporter = new MailReporter({targetAddress:"test@example.com"})
      assert.equal(reporter.maxRetries, 3)

  describe "notify", ->

    it "should call sendMail with the appropriate message", ->
      reporter = new MailReporter({targetAddress:"test@example.com"})
      reporter.notify("myMessage", {name:"myname"})
      assert.include(childProcessMock.mailCommand, "myMessage")

    it "should log error if sending mail fails", ->
      childProcessMock.exec = (command, callback) =>
        callback("someError")
      reporter = new MailReporter({targetAddress:"test@example.com"})
      reporter.notify("myMessage", {name:"myname"})
      assert.include(loglevelMock.strError, "mail delivery failed")

    it "should retry sending the mail on error", ->
      #@TODO
