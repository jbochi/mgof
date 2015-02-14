import calendar
import random
import redis
import time
import sys

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

def post_metric(key, value, timestamp=None):
    timestamp = timestamp or time.time()
    r.zadd(key, timestamp, ("%d:%f" % (timestamp, value)))


def clean_old_values(key):
    r.zremrangebyscore(key, "-inf", time.time() - TIME_SERIES_LENGTH_IN_SECONDS)


def random_point(avg=LOAD_AVG,stddev=LOAD_STDDEV):
    return min([max([random.normalvariate(avg, stddev),0]), 100])


def prepopulate(key):
    now = time.time()
    r.delete(key)
    for delta in range(0, -TIME_SERIES_LENGTH_IN_SECONDS, -METRICS_INTERVAL_IN_SECONDS):
        post_metric(key, random_point(), now + delta)
        if delta % (1000 * METRICS_INTERVAL_IN_SECONDS) == 0:
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
            value = random_point(LOAD_AVG+30, LOAD_STDDEV/2)
            print(value)
            post_metric(key, value)
            clean_old_values(key)
        except RuntimeError as err:
            print(err)
        time.sleep(1)


if __name__ == "__main__":
    main()
