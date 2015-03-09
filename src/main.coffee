App = require("./app")
log = require("loglevel")

# init commandline options
argv = require("yargs")
  .usage("Usage: $0 --tests=[test1[,test2,...]] [options]")
  .epilog("elasticwatch by Rico Pfaus | (c) 2015 | <ricopfaus@gmail.com>")
  .version () ->
    require("../package.json").version
  .option "t",
    alias : "tests"
    demand: true
    describe: "comma-separated list with test suites"
    type: "string"
  .option "h",
    alias : "host"
    default: "localhost"
    describe: "elasticsearch host"
    type: "string"
  .option "p",
    alias : "port"
    default: 9200
    describe: "comma-separated list with test suites"
    type: "number"
  .option "v",
    alias : "verbose"
    describe: "show additional output"
    type: "boolean"
  .argv

# read args and pass correct configuration to App
opts =
  tests: argv.tests?.split(',')
  host: argv.host
  port: argv.port

# set loglevel
log.setLevel(if argv.verbose then 1 else 4)

# start main logic
new App(opts)
