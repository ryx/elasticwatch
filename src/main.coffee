App = require("./app")

# TODO:
# read args and pass correct configuration to App
# ...
opts =
  tests: ["test.json", "error:/"]

# start main logic
new App(opts)
