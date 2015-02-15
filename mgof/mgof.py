import redis
import time


class AnomalyDetector():
    def __init__(self, host='localhost', port=6379):
        self.r = redis.StrictRedis(host='localhost', port=6379)

    def _serialize_value(self, timestamp, value):
        return "%f:%f" % (timestamp, value)

    def _read_value(self, string):
        ts, value = string.split(":")
        return float(ts), float(value)

    def post_metric(self, key, value, timestamp=None):
        timestamp = timestamp or time.time()
        return self.r.zadd(key, timestamp, self._serialize_value(timestamp, value))

    def get_time_series(self, key, start="-inf", stop="+inf"):
        return map(self._read_value, self.r.zrangebyscore(key, start, stop))
