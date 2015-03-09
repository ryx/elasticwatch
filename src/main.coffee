App = require("./app")
argv = require("yargs")
  .usage("Usage: $0 --tests=[test1[,test2,...]] --host=[elasticsearch_host] --port=[elasticsearch_port]")
  .demand(["tests", "host", "port"])
  .argv

# core args
#argv.version = "0.0.0"

# read args and pass correct configuration to App
opts =
  tests: argv.tests?.split(',')
  host: argv.host
  port: argv.port

# start main logic
new App(opts)
