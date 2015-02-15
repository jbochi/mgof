import mgof
import redis

TEST_KEY = "test_key"
r = redis.StrictRedis(host='localhost', port=6379)


def test_post_ang_get_metric_back():
    a = mgof.AnomalyDetector()
    r.delete(TEST_KEY)
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=14000000)
    a.get_metric(key=TEST_KEY) == [(14000000, 40.0)]


def test_get_metric_should_return_values_in_specified_range():
    ts = 14000000
    a = mgof.AnomalyDetector()
    r.delete(TEST_KEY)
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=ts)

    a.get_metric(key=TEST_KEY) == [(ts, 40.0)]
    a.get_metric(key=TEST_KEY, min_value=ts - 10, max_value=ts + 10) == [(ts, 40.0)]
    a.get_metric(key=TEST_KEY, min_value="-inf", max_value="+inf") == [(ts, 40.0)]
    a.get_metric(key=TEST_KEY, min_value=ts - 20, max_value=ts - 10) == []
    a.get_metric(key=TEST_KEY, min_value=ts + 10, max_value=ts - 20) == []
