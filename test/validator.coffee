# load testing deps
mockery = require("mockery")
assert = require("chai").assert

# mock dependencies
[worker] = []

# mock "loglevel"
loglevelMock =
  debug: (str) ->
    @strDebug = str
  error: (str) ->
    @strError = str
    #console.error(str)  # so we see errors in console output

# setup mockery
mockery.enable({
  useCleanCache: true
})
mockery.registerMock("loglevel", loglevelMock)
mockery.registerAllowables(["../src/validator"])

# load module to be tested
Validator = require("../src/validator")

describe "Validator", ->

  describe "constructor", ->

    it "should break if any argument of [fieldName,min,max,tolerance] is missing", ->
      assert.throw((->new Validator(null, 10, 20, 5)), Error, "invalid number of options")
      assert.throw((->new Validator("prop", null, 20, 5)), Error, "invalid number of options")
      assert.throw((->new Validator("prop", 10, null, 5)), Error, "invalid number of options")
      assert.throw((->new Validator("prop", 10, 20, null)), Error, "invalid number of options")

  describe "validate", ->
    [validator] = []

    beforeEach ->
      validator = new Validator("prop", 10, 30, 4)

    it "should return false if no data is supplied", ->
      assert.isFalse(validator.validate())

    it "should return false if 5 consecutive values within the result are below the expectation", ->
      result =
        hits:
          hits: [
            {_source:{prop:5}}
            {_source:{prop:7}}
            {_source:{prop:6}}
            {_source:{prop:9}}
            {_source:{prop:4}}
          ]
      assert.isFalse(validator.validate(result))

    it "should return false if 5 consecutive values within the result are above the expectation", ->
      result =
        hits:
          hits: [
            {_source:{prop:35}}
            {_source:{prop:37}}
            {_source:{prop:36}}
            {_source:{prop:39}}
            {_source:{prop:34}}
          ]
      assert.isFalse(validator.validate(result))

    it "should return true if less than 5 consecutive values within the result are below the expectation", ->
      result =
        hits:
          hits: [
            {_source:{prop:5}}
            {_source:{prop:7}}
            {_source:{prop:6}}
            {_source:{prop:9}}
            {_source:{prop:11}}
          ]
      assert.isTrue(validator.validate(result))

    it "should return true if less than 5 consecutive values within the result are above the expectation", ->
      result =
        hits:
          hits: [
            {_source:{prop:35}}
            {_source:{prop:37}}
            {_source:{prop:36}}
            {_source:{prop:39}}
            {_source:{prop:29}}
          ]
      assert.isTrue(validator.validate(result))

    it "should return true if all values within the result meet the expectation", ->
      result =
        hits:
          hits: [
            {_source:{prop:12}}
            {_source:{prop:17}}
            {_source:{prop:22}}
            {_source:{prop:23}}
            {_source:{prop:27}}
          ]
      assert.isTrue(validator.validate(result))
