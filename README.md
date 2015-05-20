# elasticwatch

Elasticwatch is a nifty tool that queries an elasticsearch database and compares the results to a given expectation. If the results don't match the expectation a reporter is notified and can perform any kind of action (e.g. heat up the coffeemaker via IFTTT before sending an email to your dev team ;-) ...).

This allows to create intelligent alarming setups based on your ELK data, no matter if it's gathered from infrastructure monitoring, RUM data, ecommerce KPIs or anything else. No other tools needed, if set up as a cronjob.

## Getting started

First clone the git repository and install the dependencies.
```
git clone https://github.com/ryx/elasticwatch.git
cd elasticwatch
npm install
```

Then create some data in your elasticsearch ...
```bash
curl -s -XPUT 'http://localhost:9200/monitoring/rum/1' -d '{"requestTime":43,"responseTime":224,"renderTime":568,"timestamp":"2015-03-06T11:47:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/2' -d '{"requestTime":49,"responseTime":312,"renderTime":619,"timestamp":"2015-03-06T12:02:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/3' -d '{"requestTime":41,"responseTime":275,"renderTime":597,"timestamp":"2015-03-06T12:17:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/4' -d '{"requestTime":42,"responseTime":301,"renderTime":542,"timestamp":"2015-03-06T12:32:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/5' -d '{"requestTime":48,"responseTime":308,"renderTime":604,"timestamp":"2015-03-06T12:47:34"}'
curl -s -XPUT 'http://localhost:9200/monitoring/rum/6' -d '{"requestTime":43,"responseTime":256,"renderTime":531,"timestamp":"2015-03-06T13:02:34"}'
```

... and run elasticwatch with the included *example.json* from the `jobs` dir. (*NOTE: make sure you have an elasticsearch instance up and running at the given URL*)
```
bin/elasticwatch --jobs=jobs/example.json
```

## Jobs
Jobs are files that tell elasticwatch what to do. This includes: where to find the db host, what data to query from the database, which target values to compare the data to and what to do when alarm conditions are met.

The job configuration files reside in the `jobs` directory as plain JSON files that may contain the following properties. Check the [example.json](jobs/example.json) for a basic example.

### *name (required)*
A name of your choice to identify this job.

### *info*
Any kind of info that describes this job.

### *elasticsearch (required)*
Settings for elasticsearch, expects the following madatory fields:
- *host*: where to find the elasticsearch host
- *port*: which port elasticsearch is running on
- *index*: the index name to send youe query to
- *type*: the document type to query

### *query* (required)
An elasticsearch query statement. Refer to the [elasticsearch documentation](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current) for details about syntax and features. Should return a result set that contains the supplied *fieldName* to match against.

### *fieldName* (required)
The name of the field in the result set, that is compared against the defined expectation.

### *min* (required)
The minimum allowed value for all values within the query. If a series of values (as defined through the *tolerance* property) in the result is lower than this minimum an alarm is raised and reported.

### *max* (required)
The maxmimum allowed value for all values within the query. If a series of values (as defined through the *tolerance* property) in the result exceed this maximum an alarm is raised and reported.

### *tolerance* (required)
If a queried series of values exceeds either *min* or *max* for *tolerance*+1 times an alarm is raised.

## Reporters

### About reporters
By default elasticwatch does nothing more than executing its configured jobs, raising alarms if expectations aren't met. If you want to perform any action in such an alarm case, you have to define a reporter.

To put it simple - reporters are notified about alarms, which means a configured expectation isn't met for a given number of times. They can then do helpful things depending on their type like sending an email, creating a ticket in your ticket system, etc.

Reporters are defined inside a job's config, you can set either one or multiple of them. Most reporters need a specific configuration that is based on the reporter type and defined as a JSON string.

### Available reporters

#### ConsoleReporter
The ConsoleReporter is just meant for demonstration purpose and simply logs a message to the console.

#### EMailReporter
TODO

### Custom reporters
You can create custom reporters by creating a new class that extends the `Reporter` class (see [ConsoleReporter](src/reporters/console.coffee) for an example).

## TODO
- branch event-emitter:
-- revive and finish tests
-- move optionhandling to OptionParser
-- use commandline as default option source and use external JSON only as a fallback (with option --config=)
