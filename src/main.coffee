App = require("./app")
log = require("loglevel")

# init commandline options
argv = require("yargs")
  .usage("Usage: $0 --tests=[test1[,test2,...]] [options]")
  .epilog("elasticwatch by Rico Pfaus | (c) 2015 | <ricopfaus@gmail.com>")
  .version () ->
    require("../package.json").version
  .option "j",
    alias : "jobs"
    demand: true
    describe: "comma-separated list with jobs"
    type: "string"
  .option "v",
    alias : "verbose"
    describe: "show additional output"
    type: "boolean"
  .option "r",
    alias : "reporters"
    describe: "reporters to notify about alarms (as hash with name:config)"
  #  type: "string"
  .argv

log.debug("Reporters: ", argv.reporters)

# read args and pass correct configuration to App
opts =
  jobs: argv.jobs?.split(',')
  reporters: if argv.reporters then JSON.parse(argv.reporters) else {}


# TODO: opts = options.parse()

# set loglevel
log.setLevel(if argv.verbose then 1 else 4)

# start main logic
new App(opts)
