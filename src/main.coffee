App = require("./app")
log = require("loglevel")
yargs = require("yargs")

# init commandline options
argv = yargs
  .usage("Usage: $0 --name=[name] --[elasticsearch,query,reporters,validator]={...} or --config=[config]")
  .epilog("elasticwatch by Rico Pfaus | (c) 2015 | <ricopfaus@gmail.com>")
  .version () ->
    require("../package.json").version
  .option "name",
    describe: "identifier for this Job (will be included in reports)"
    type: "string"
  .option "elasticsearch",
    describe: "object with elasticsearch settings [host|port|index|type]"
    type: "string"
  .option "query",
    describe: "elasticsearch query (e.g. {\"match\":\"*\"})"
    type: "string"
  .option "reporters",
    describe: "reporters to notify about alarms (as hash with name:config)"
    type: "string"
  .option "validator",
    describe: "validator for checking expectation (as hash with name:config)"
    type: "string"
  .option "configfile",
    describe: "optional file with JSON data that supplies all options [elasticsearch|query|validator|reporters]"
    type: "string"
  .option "debug",
    describe: "show additional output (for debugging only)"
    type: "boolean"
  .argv

# build options - either from configfile or from commandline
if argv.configfile
  try
    # @FIXME: map local to global path (currently only global paths accepted)
    opts = require(argv.configfile)
  catch e
    log.error("ERROR: failed loading configfile: #{e.message}")
    process.exitCode = 10
else
  if not (argv.name or argv.elasticsearch or argv.query or argv.reporters or argv.validator)
    log.error(yargs.help())
    process.exitCode = 11
  else
    try
      opts =
        name: argv.name
        elasticsearch: JSON.parse(argv.elasticsearch)
        query: JSON.parse(argv.query)
        validator: JSON.parse(argv.validator)
        reporters: JSON.parse(argv.reporters)
    catch e
      log.error("ERROR: failed parsing commandline options: #{e.message}")
      process.exitCode = 12

# exit on error
if process.exitCode > 9
  process.exit()

# set loglevel
log.setLevel(if argv.debug then 1 else 4)

# start main logic and hand over options
new App(opts)
