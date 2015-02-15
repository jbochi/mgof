import redis


class AnomalyDetector():
    def __init__(self, host='localhost', port=6379):
        self.r = redis.StrictRedis(host='localhost', port=6379)

    def post_metric(self, key, value, timestamp=None):
        timestamp = timestamp or time.time()
        return self.r.zadd(key, timestamp, ("%d:%f" % (timestamp, value)))

    def get_metric(self, key, min_value, max_value):
        return self.r.zcount(key, min_value, max_value)
