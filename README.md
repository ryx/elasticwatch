# elasticwatch

Elasticwatch is a nifty tool that queries an elasticsearch database and compares the results to a given expectation. If the results don't match the expectation a reporter is notified and can perform any kind of action (e.g. heat up the coffeemaker via IFTTT before sending an email to your dev team ;-) ...).

This allows to create intelligent alarming setups based on your ELK data, no matter if it's gathered from infrastructure monitoring, RUM data, ecommerce KPIs or anything else. No other tools needed, if set up as a cronjob.

## Getting started

### Installation
Just checkout the git repository and install the dependencies.
```
git checkout https://github.com/ryx/elasticwatch.git
cd elasticwatch
npm install
```

### Prerequisites
Create some data in your elasticsearch
```bash
curl -s -XPUT 'http://localhost:9200/monitoring/rum/1' -d '{"requestTime":43,"responseTime":224,"renderTime":568,"timestamp":"2015-03-06T11:47:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/2' -d '{"requestTime":49,"responseTime":312,"renderTime":619,"timestamp":"2015-03-06T12:02:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/3' -d '{"requestTime":41,"responseTime":275,"renderTime":597,"timestamp":"2015-03-06T12:17:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/4' -d '{"requestTime":42,"responseTime":301,"renderTime":542,"timestamp":"2015-03-06T12:32:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/5' -d '{"requestTime":48,"responseTime":308,"renderTime":604,"timestamp":"2015-03-06T12:47:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/6' -d '{"requestTime":43,"responseTime":256,"renderTime":531,"timestamp":"2015-03-06T13:02:34"}'
```

Then create a simple test configuration within the `tests` dir that raises an alarm when running over our previously inserted data.
```json
{
  "name": "SimpleJob",
  "info": "This job should demonstrate the basic principles of elasticwatch",
  "host": "localhost",
  "port": 9200,
  "index": "monitoring",
  "type": "rum",
  "query": {
    "filtered": {
      "query": {
        "query_string": {
          "query": "_exists_:renderTime",
          "analyze_wildcard": true
        }
      },
      "filter": {
        "range" : {
          "timestamp" : {
            "gt" : "2015-03-06T12:00:00",
            "lt" : "2015-03-07T00:00:00"
          }
        }
      }
    }
  },
  "fieldName": "renderTime",
  "min": 0,
  "max": 500,
  "tolerance": 4,
  "reporters": {
    "console": {
      "prefix": "Simple test"
    }
  }
}
```

### Running elasticwatch
Now run the application (*make sure you have an elasticsearch instance up and running at the given location*)
```
bin/elasticwatch --jobs=simple.json --host=localhost --port=9200
```

## Configuration
The configuration files reside in the `config` directory as plain JSON files that may contain the following properties.

### *name*
A name of your choice to identify this job.

### *info*
Any kind of info that describes this job.

### *query*
An elasticsearch query statement. Refer to the [elasticsearch documentation](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current) for details about syntax and features. Should return a result set that contains the supplied *fieldName* to match against.

### *fieldName*
The name of the field to match the expectation against.

### *min*
The minimum allowed value for all values within the query. If a series of values (as defined through the *tolerance* property) in the result is lower than this minimum an alarm is raised and reported.

### *max*
The maxmimum allowed value for all values within the query. If a series of values (as defined through the *tolerance* property) in the result exceed this maximum an alarm is raised and reported.

### *tolerance*
If a queried series of values exceeds either *min* or *max* for *tolerance*+1 times an alarm is raised.

## Reporters

### About reporters
By default elasticwatch does nothing more than executing its configured jobs, raising alarms if expectations aren't met. If you want to perform any action in such case, you have to define a reporter.

To put it simple - reporters are notified about alarms, which means a configured expectation isn't met for a given number of times. They can then do helpful things depending on their type like sending an email, creating a ticket in your ticket system, etc.

Reporters are defined inside a job's config, you can set either one or multiple of them. Most reporters need a specific configuration that is based on the reporter type and defined as a JSON string.

### Available reporters

#### ConsoleReporter
The ConsoleReporter is just meant for demonstration purpose and simply logs a message to the console.

#### EMailReporter
TODO

### Custom reporters
You can create custom reporters by creating a new class that extends the `Reporter` class (see [ConsoleReporter](reporters/ConsoleReporter.coffee) for an example).
