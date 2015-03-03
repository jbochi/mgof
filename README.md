#mgof

[![Build Status][badge-travis-image]][badge-travis-url]

mgof stands for Multinomial Goodness of Fit. It is an Anomaly Detection system backed by Redis.

The algorithm is based on the paper ["Statistical Techniques for Online Anomaly Detection in Data Centers"](http://www.hpl.hp.com/techreports/2011/HPL-2011-8.pdf).

The anomaly detector is implemented with Lua scripts in Redis avoiding the need
to fetch a time series for processing. This saves network bandwidth, but depending on the
length of the time series, the CPU usage can be high and block Redis.

This is the perfect use case for the [parallel redis fork](https://github.com/jbochi/parallel_redis).

mgof is an academic research project still in progress. Consider using
[morgoth](https://github.com/nvcook42/morgoth) if you need a more madure alternative.


##Running tests

Redis should be running locally at the default port (6379) or available at `REDIS_HOST` and `REDIS_PORT`.

WARNING: The Redis db will be flushed

###Lua unit and functional tests

- Install [busted](http://olivinelabs.com/busted/) and lua-cjson rock
- Run make `make test_lua`

###Python integration tests

- Run `make install_dev`
- Run `make test_python`

###Testing everything

- See integration and unit tests dependencies
- Run `make test`

[badge-travis-url]: https://travis-ci.org/jbochi/mgof
[badge-travis-image]: https://img.shields.io/travis/jbochi/mgof.svg?style=flat


## Utils

- Install python dependencies: `pip install -r requirements-utils.txt`

### Import data from graphite

`python util/import_from_graphite.py graphite.example.com "live.server.request_time.mean" --key request_time  --start="-14days"`

### Detect anomalies

`python util/anomaly_detector.py request_time --min_value 0 --max_value 250000 --window_size 7200 --confidence="99.5" --redis_port=7000`

### Plot data

`python util/plot_series.py request_time`

![](https://raw.githubusercontent.com/jbochi/mgof/master/mgof.png)
