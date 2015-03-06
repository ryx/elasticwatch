# elasticwatch v0.0.0

Elasticwatch is a nifty tool that periodically queries an elasticsearch database and compares the results to a given expectation. If the results don't match the expectation a reporter is notified and can perform any kind of action (e.g. send an email to your dev team).

This allows to create intelligent alarming setups based on your ELK data, no matter if it's gathered from infrastructure monitoring, RUM data, ecommerce KPIs or anything else.

## Getting started
Just checkout the git repository and install the dependencies.
```
git checkout https://github.com/ryx/elasticwatch.git
cd elasticwatch
npm install
```

Then create a simple configuration within the `config` dir.
```json
{
  "name": "My testing config",
  "desc": "a very simple example for an elasticwatch configuration",
  "query": {
    "query": "*"
  },
  "min": 0,
  "max": 100,
  "tolerance": 10,
  "reporters": {
    "console": {},
    "email": {
      "recipients": [
        "bob@example.com",
        "cindy@example.com"
      ]
    }
  }
}
```

Now run the application (*make sure you have a local elasticsearch instance up and running at the given location*)
```
bin/elasticwatch --elasticsearch-host=http://localhost:9200
```

## Configuration
The configuration files reside in the `config` directory as plain JSON files that may contain the following properties.

### *query*
An elasticsearch query statement. Refer to the [elasticsearch documentation](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current) for details about syntax and features.

### *min*
The minimum allowed value for all values within the query. If a series of values (as defined through the *tolerance* property) in the result is lower than this minimum an alarm is raised and reported.

### *max*
The maxmimum allowed value for all values within the query. If a series of values (as defined through the *tolerance* property) in the result exceed this maximum an alarm is raised and reported.

### *tolerance*
If a queried series of values exceeds either *min* or *max* for *tolerance*+1 times an alarm is raised.

## Reporters

### About reporters
By default elasticwatch does nothing more than executing its configured actions, raising alarms if expectations aren't met. If you want to perform any action in such case, you have to define a reporter.

To put it simple - reporters are notified about alarms, which means a configured expectation isn't met for a given number of times. They can then do helpful things depending on their type like sending an email, creating a ticket in your ticket system, etc.

Reporters a defined inside the config, you can set either one or multiple of them. Most reporters need a specific configuration that is based on the reporter type and defined as a JSON string. See section [Configuration](#configuration) for an example reporter config.

### Custom reporters
You can create custom reporters by creating a new class that extends `EWReporter` from the `core` module.
