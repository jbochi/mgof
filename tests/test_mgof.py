import mgof
import redis

TEST_KEY = "test_key"
r = redis.StrictRedis(host='localhost', port=6379)


def test_post_ang_get_metric_back():
    a = mgof.AnomalyDetector()
    r.delete(TEST_KEY)
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=14000000)

    assert a.get_metric(key=TEST_KEY) == [(14000000, 40.0)]


def test_get_metric_should_return_values_in_specified_range():
    ts = 14000000
    a = mgof.AnomalyDetector()
    r.delete(TEST_KEY)
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=ts)

    assert a.get_time_series(key=TEST_KEY) == [(ts, 40.0)]
    assert a.get_time_series(key=TEST_KEY, start=ts - 10, stop=ts + 10) == [(ts, 40.0)]
    assert a.get_time_series(key=TEST_KEY, start="-inf", stop="+inf") == [(ts, 40.0)]
    assert a.get_time_series(key=TEST_KEY, start=ts - 20, stop=ts - 10) == []
    assert a.get_time_series(key=TEST_KEY, start=ts + 10, stop=ts - 20) == []
