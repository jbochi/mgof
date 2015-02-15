import redis


class AnomalyDetector():
    def __init__(self, host='localhost', port=6379):
        self.r = redis.StrictRedis(host='localhost', port=6379)

    def post_metric(self, key, value, timestamp=None):
        timestamp = timestamp or time.time()
        self.r.zadd(key, timestamp, ("%d:%f" % (timestamp, value)))
