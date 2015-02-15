import mgof
import redis

TEST_KEY = "test_key"
r = redis.StrictRedis(host='localhost', port=6379)


def test_post_ang_get_metric_back():
    a = mgof.AnomalyDetector()
    r.delete(TEST_KEY)
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=14000000)
    a.get_metric(key=TEST_KEY, min_value="-inf", max_value="inf") == [(14000000, 40.0)]
