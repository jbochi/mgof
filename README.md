mgof
====

mgof stands for Multinomial Goodness of Fit. It is an Anomaly Detection algorithm for time series stored in Redis.

The algorithm is based on the paper ["Statistical Techniques for Online Anomaly Detection in Data Centers"](http://www.hpl.hp.com/techreports/2011/HPL-2011-8.html).

Since the anomaly detector is implemented in Lua and run with Redis' EVAL command, there is no need
to fetch the whole time series, saving network bandwidth. Depending on the length of the time series,
the CPU usage can be high though. This is a possible use case
for [parallel redis](https://github.com/jbochi/parallel_redis).

This is a work in progress and will propably be just an academic project. Consider using
[morgoth](https://github.com/nvcook42/morgoth) for real world scenarios.


Running integration tests
-------------------------

- Run parallel redis locally
- Install python dependencies: `pip install -r requirements-dev.txt`
- py.test


Unit tests
----------

- Run [busted](http://olivinelabs.com/busted/)
