App = require("./app")
pkg = require("../package.json")
log = require("loglevel")

# init commandline options
argv = require("yargs")
  .usage("Usage: $0 --tests=[test1[,test2,...]] --host=[elasticsearch_host] --port=[elasticsearch_port] [options]")
  .describe("tests", "comma-separated list with test suites")
  .describe("host", "elasticsearch host")
  .describe("port", "elasticsearch port")
  .describe("verbose", "Show additional output")
  .demand(["tests", "host", "port"])
  .epilog("elasticwatch v#{pkg.version} | (c) 2015 Rico Pfaus")
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
