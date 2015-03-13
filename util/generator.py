import calendar
import random
import redis
import time
import sys
import os

path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(path)

import mgof

SECOND = 1
MINUTE = 60 * SECOND
HOUR = 60 * MINUTE
DAY = 24 * HOUR
MONTH = 30 * DAY
TIME_SERIES_LENGTH_IN_SECONDS = MONTH
METRICS_INTERVAL_IN_SECONDS = 30 * SECOND

LOAD_AVG = 50
LOAD_STDDEV = 15


r = redis.StrictRedis(host='localhost', port=6379)
a = mgof.AnomalyDetector(host='localhost', port=6379)


def random_value(avg=LOAD_AVG, stddev=LOAD_STDDEV):
    return min([max([random.normalvariate(avg, stddev),0]), 100])


def prepopulate(key):
    now = time.time()
    r.delete(key)
    metrics = {}
    for delta in range(0, -TIME_SERIES_LENGTH_IN_SECONDS, -METRICS_INTERVAL_IN_SECONDS):
        metrics[now + delta] = random_value()
        if delta % (1000 * METRICS_INTERVAL_IN_SECONDS) == 0:
            a.post_metrics(key, metrics)
            metrics = {}
            sys.stdout.write(".")
            sys.stdout.flush()

def main():
    key = "load"
    print "Prepopulating key %s" % key
    prepopulate(key)
    print
    print "Adding new points..."
    while True:
        try:
            value = random_value(LOAD_AVG + 30, LOAD_STDDEV / 2.0)
            print(value)
            a.post_metric(key, value)
            a.clean_old_values(key, TIME_SERIES_LENGTH_IN_SECONDS)
        except RuntimeError as err:
            print(err)
        time.sleep(1)


if __name__ == "__main__":
    main()
